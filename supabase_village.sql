-- ============================================================================
--  صفحة القرية — تأسيس قاعدة البيانات (Supabase)
--  سجل أهل القرية: الاسم + رقم التليفون + الرقم القومي.
-- ----------------------------------------------------------------------------
--  طريقة التنفيذ:
--    1) Supabase Dashboard  ->  SQL Editor  ->  New query
--    2) الصق محتوى هذا الملف بالكامل ثم اضغط Run
--  السكريبت Idempotent — يمكن إعادة تشغيله بأمان دون فقدان بيانات.
-- ----------------------------------------------------------------------------
--  مبدأ الأمان:
--   * كل الجداول محمية بـ Row Level Security: ولا يملك دور `anon` أي وصول
--     مباشر إلى `villages` أو `members` أو `village_admins` أو `local_ads`
--     إطلاقاً — وحدهما جدولا `videos` و`local_ads` قراءتهما عامة (المحتوى
--     المُعلَن لا السرّ)، بسياسات تمنع غير النشط من الظهور.
--   * الزائر (غير المسجَّل) لا يُدخل شيئاً بنفسه: الإدراج يمرّ حصراً من دالة
--     `village_register_member` التي تتحقق من الكود والاسم والتليفون والرقم
--     القومي (وتستخرج تاريخ الميلاد والسن) على السيرفر.
--   * حقّ الحذف مضمون بالمثل: دالة `village_delete_member` تحذف بيانات عضو
--     بمطابقة رقميه القومي والتليفون معاً، فلا يستطيع أحد حذف بيانات غيره.
--   * المستخدم المسجَّل (مسؤول القرية) لا يرى إلا أعضاء قريته وحدها، ولا يُدرج
--     في جدول الفيديوهات إلا ما يخصّ قريته وحدها.
--   ملاحظة: لا نُفعّل `force row level security` عن قصد — الدوال تعمل بـ
--   `security definer`، وفرض RLS على مالك الجدول يعطّل مسار الإدراج المشروع.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0) ملحقات مساعدة
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()


-- ============================================================================
-- 1) جدول public.villages — القرى
--    الكود هو مفتاح التسجيل المُوزَّع على الأهالي، وهو فريد لكل قرية.
-- ============================================================================
create table if not exists public.villages (
  id         uuid        primary key default gen_random_uuid(),
  name       text        not null,
  code       text        not null,
  created_at timestamptz not null default now(),
  constraint villages_name_not_blank check (length(btrim(name)) > 0),
  -- الصيغة: ثلاثة حروف لاتينية + شرطة + أربعة أرقام  (مثل MAA-2026)
  constraint villages_code_format    check (code ~ '^[A-Z]{3}-[0-9]{4}$'),
  constraint villages_code_unique    unique (code)
);

comment on table  public.villages      is 'قرى المبادرة — كل قرية لها كود تسجيل فريد يوزَّع على أهلها';
comment on column public.villages.code is 'كود التسجيل بصيغة AAA-0000 (حروف لاتينية كبيرة + السنة)';

-- تطبيع الكود تلقائياً (حروف كبيرة بلا مسافات) قبل أي إدراج أو تعديل.
create or replace function public.villages_normalize_code()
returns trigger
language plpgsql
as $$
begin
  new.code := upper(btrim(new.code));
  new.name := btrim(new.name);
  return new;
end;
$$;

drop trigger if exists villages_normalize_code_trg on public.villages;
create trigger villages_normalize_code_trg
  before insert or update on public.villages
  for each row execute function public.villages_normalize_code();


-- ============================================================================
-- 2) جدول public.members — أعضاء القرية (الأهالي المسجَّلون)
--    تاريخ الميلاد والسن عمودان محسوبان من الرقم القومي على السيرفر، لا من
--    مدخلات العميل.
-- ============================================================================
create table if not exists public.members (
  id          uuid        primary key default gen_random_uuid(),
  village_id  uuid        not null references public.villages (id) on delete cascade,
  name        text        not null,
  phone       text        not null,
  national_id text        not null,
  birth_date  date        not null,
  age         int         not null,
  created_at  timestamptz not null default now(),
  constraint members_name_min_length  check (length(btrim(name)) >= 3),
  -- تليفون محمول مصري: 11 رقماً يبدأ بـ 010/011/012/015
  constraint members_phone_format     check (phone ~ '^01[0125][0-9]{8}$'),
  -- رقم قومي: 14 رقماً يبدأ بقرن 2 (‎1900s‎) أو 3 (‎2000s‎)
  constraint members_nid_format       check (national_id ~ '^[23][0-9]{13}$'),
  constraint members_national_id_key  unique (national_id),
  constraint members_age_minimum      check (age >= 18),
  constraint members_birth_not_future check (birth_date <= current_date)
);

-- الموافقة القانونية — الامتثال لقانون حماية البيانات الشخصية المصري 151/2020:
-- يُحفظ وقت الموافقة على النموذج (التي لا يُتمّ التسجيل بدونها) وإصدارا
-- النصّين المُقرَأين، فيبقى في السجلّ ما شهد به وقت التسجيل.
alter table public.members
  add column if not exists agreed_at       timestamptz default now(),
  add column if not exists terms_version   text default '1.0.0',
  add column if not exists privacy_version text default '1.0.0';

comment on column public.members.agreed_at       is 'زمن الموافقة على الشروط والخصوصية (لحظة التسجيل)';
comment on column public.members.terms_version   is 'إصدار شروط الاستخدام المُقرَأ وقت التسجيل';
comment on column public.members.privacy_version is 'إصدار سياسة الخصوصية المُقرَأة وقت التسجيل';

comment on table  public.members             is 'أهل القرية المسجَّلون عبر صفحة التسجيل العامة';
comment on column public.members.national_id is 'الرقم القومي (14 رقماً) — فريد على مستوى المنصة كلها';
comment on column public.members.birth_date  is 'تاريخ الميلاد المستخرج من الرقم القومي';
comment on column public.members.age         is 'السن بالسنوات الكاملة لحظة التسجيل (يجب ألا تقل عن 18)';

create index if not exists members_village_idx
  on public.members (village_id);
create index if not exists members_village_created_idx
  on public.members (village_id, created_at desc);

-- 2.1 تنظيف التكرار ثم فرض قيد الفريد على الرقم القومي.
--     المبدأ: **رقم قومي واحد = شخص واحد**؛ أما التليفون فيُسمَح بتكراره
--     (أب وابن على نفس الرقم مثلاً). القيد موجود في تعريف الجدول أعلاه،
--     لكن قاعدة بيانات أُنشئت قبل إضافته قد بقيت بلا قيد فدخلها تكرار —
--     فهذا المقطع يجعلها مطابقة، ويُشغَّل بأمانة على قاعدةٍ نظيفة أو ملوثة.
--     (الحذف والأسماء كلها معرّفات `if exists`، فالتشغيل المتكرر بلا أثر.)
--
-- (أ) تطبيع أي رقم قومي كُتب قديماً بمسافات أو شرطات أو أرقام عربية-هندية —
--     وفقط إن كان ناتجه رقماً صحيحاً (14 رقماً يبدأ بـ 2 أو 3)، وإلا يبقى
--     كما هو فلا نُفقد بيانات ولا نكسر قيد الصيغة.
update public.members
   set national_id = regexp_replace(national_id, '[^0-9]', '', 'g')
 where national_id <> regexp_replace(national_id, '[^0-9]', '', 'g')
   and regexp_replace(national_id, '[^0-9]', '', 'g') ~ '^[23][0-9]{13}$';

-- (ب) حذف الصفوف المكرّرة — يُبقَى **الأقدم** (`created_at`)، وعند التساوي
--     يُبقَى الأصغر `id`. (ملاحظة: `id` عشوائي uuid، فـ `min(id)` وحده
--     لا يعني «الأقدم».)
delete from public.members
 where id in (
   select id
     from (
       select id,
              row_number() over (
                partition by national_id
                order by created_at, id
              ) as rn
         from public.members
     ) ranked
    where rn > 1
 );

-- (ج) قيد الفريد — يُحذف أي اسم سابق للمقيد ثم يُضاف الاسم المعتمد، فلا
--     يتراكم قيدان متطابقان على العمود نفسه.
alter table public.members
  drop constraint if exists members_nid_unique;

alter table public.members
  drop constraint if exists members_national_id_key;

alter table public.members
  add constraint members_national_id_key unique (national_id);

comment on constraint members_national_id_key on public.members is
  'رقم قومي واحد = شخص واحد (التليفون وحده هو المسموح بتكراره)';


-- ============================================================================
-- 3) جدول public.village_admins — ربط حساب مسؤول القرية بقريته
--    يُستخدم في تطبيق JoodCraft: المستخدم يُدخل كود القرية فيُربط حسابه بها،
--    ومن ثم لا يرى إلا أعضاء قريته.
-- ============================================================================
create table if not exists public.village_admins (
  user_id    uuid        primary key references auth.users (id) on delete cascade,
  village_id uuid        not null references public.villages (id) on delete cascade,
  role       text        not null default 'owner'
                         check (role in ('owner', 'admin')),
  created_at timestamptz not null default now()
);

comment on table public.village_admins is 'صلاحية الوصول: حساب مسجَّل ⇒ قرية واحدة (owner ينشئ، admin يقرأ)';

create index if not exists village_admins_village_idx
  on public.village_admins (village_id);


-- ============================================================================
-- 4) جدول public.videos — فيديوهات القرية (يوتيوب)
--    تُضاف مؤقتاً يدوياً من SQL Editor (لا توجد واجهة إضافة بعد)، وتُعرض في
--    قسم «فيديوهات القرية» بصفحة القرية للزائر بلا تسجيل دخول.
--    حذف القرية يحذف فيديوهاتها تلقائياً (`on delete cascade`).
-- ============================================================================
create table if not exists public.videos (
  id           uuid        primary key default gen_random_uuid(),
  village_id   uuid        not null references public.villages (id) on delete cascade,
  title        text        not null,
  youtube_url  text        not null,
  youtube_id   text        not null,
  description  text,
  published_at timestamptz default now(),
  created_at   timestamptz default now()
);

comment on table  public.videos              is 'فيديوهات القرية على يوتيوب — تُضاف يدوياً وتُقرأ علناً من الصفحة';
comment on column public.videos.youtube_url  is 'رابط الفيديو كما هو (watch?v= أو youtu.be أو shorts)';
comment on column public.videos.youtube_id   is 'معرّف الفيديو داخل الرابط — يُبنى منه إطار التضمين';
comment on column public.videos.published_at is 'موعد النشر — تاريخ مستقبلي يعني مخفياً حتى موعده';

-- نسبة أبعاد المشغّل — 16:9 (يوتيوب عادي) / 9:16 (شورتس) / 1:1 (مربع) / 4:5.
alter table public.videos
  add column if not exists aspect_ratio text default '16:9';

comment on column public.videos.aspect_ratio is 'نسبة أبعاد الفيديو (16:9|9:16|1:1|4:5) — تُشتقّ من الرابط عند الإضافة';

create index if not exists videos_village_id_idx
  on public.videos (village_id);

-- استخراج `youtube_id` من الرابط عند تركه فارغاً — يسهّل الإضافة اليدوية:
--   insert into public.videos (village_id, title, youtube_url)
--   values (…, 'عنوان الفيديو', 'https://youtu.be/XXXXXXXXXXX');
create or replace function public.videos_fill_youtube_id()
returns trigger
language plpgsql
as $$
declare
  v_url text := btrim(coalesce(new.youtube_url, ''));
  v_id  text := nullif(btrim(coalesce(new.youtube_id, '')), '');
begin
  if v_id is null and v_url ~ '^[A-Za-z0-9_-]{6,20}$' then
    -- الرابط معرّف خام (بدون https) — يُعتمد كما هو.
    v_id := v_url;
  end if;

  if v_id is null then
    v_id := substring(
      v_url from
      '(?:youtu\.be/|[?&]v=|/(?:embed|shorts|live|v)/)([A-Za-z0-9_-]{6,20})'
    );
  end if;

  if v_id is null or v_id !~ '^[A-Za-z0-9_-]{6,20}$' then
    raise exception 'تعذّر استخراج معرّف الفيديو من رابط يوتيوب'
      using errcode = 'P0001';
  end if;

  new.youtube_id  := v_id;
  new.youtube_url := v_url;
  new.title       := btrim(coalesce(new.title, ''));
  return new;
end;
$$;

comment on function public.videos_fill_youtube_id() is 'استخراج youtube_id من الرابط وتطبيعه قبل الإدراج/التعديل';

drop trigger if exists videos_fill_youtube_id_trg on public.videos;
create trigger videos_fill_youtube_id_trg
  before insert or update on public.videos
  for each row execute function public.videos_fill_youtube_id();


-- ============================================================================
-- 5) دوال مساعدة لسياسات RLS
-- ============================================================================
-- قرية المستخدم الحالي (‎null‎ إن لم يكن مرتبطاً بأي قرية).
create or replace function public.current_village_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.village_id
    from public.village_admins a
   where a.user_id = auth.uid()
   limit 1;
$$;

comment on function public.current_village_id() is 'قرية المستخدم المسجَّل الحالي — أساس كل سياسات RLS';

-- هل المستخدم الحالي من مسؤولي هذه القرية؟
create or replace function public.is_village_member_of(p_village uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.village_admins a
     where a.user_id = auth.uid()
       and a.village_id = p_village
  );
$$;


-- ============================================================================
-- 6) Row Level Security
-- ============================================================================
alter table public.villages       enable row level security;
alter table public.members        enable row level security;
alter table public.village_admins enable row level security;
alter table public.videos         enable row level security;

-- ---------------------------- 6.1 القرى ----------------------------
drop policy if exists "villages_select_own_village" on public.villages;
create policy "villages_select_own_village"
  on public.villages for select
  to authenticated
  using (id = public.current_village_id());

-- لا سياسة إدراج/تعديل/حذف للقرى من الواجهة: الإدارة من SQL Editor أو من
-- دالة claim_village_admin، فلا يستطيع أي حساب إنشاء قرى أو تعديل أكوادها.

-- ---------------------------- 6.2 الأعضاء ----------------------------
-- القراءة والتعديل والحذف: مقصورة على أعضاء قرية المستخدم الحالي.
drop policy if exists "members_select_own_village" on public.members;
create policy "members_select_own_village"
  on public.members for select
  to authenticated
  using (village_id = public.current_village_id());

drop policy if exists "members_update_own_village" on public.members;
create policy "members_update_own_village"
  on public.members for update
  to authenticated
  using    (village_id = public.current_village_id())
  with check (village_id = public.current_village_id());

drop policy if exists "members_delete_own_village" on public.members;
create policy "members_delete_own_village"
  on public.members for delete
  to authenticated
  using (village_id = public.current_village_id());

-- **لا سياسة INSERT إطلاقاً** (لا لـ anon ولا لـ authenticated): كل إدراج يمرّ
-- من دالة village_register_member بعد التحقق الكامل. هذا هو جوهر التصميم:
-- الصفحة عامة، لكن الجدول ليس مفتوحاً.

-- ------------------------ 6.3 ارتباط المسؤولين ------------------------
-- كل حساب يرى صفّ ارتباطه هو فقط (ولا يرى هوية بقية المسؤولين).
drop policy if exists "village_admins_select_self" on public.village_admins;
create policy "village_admins_select_self"
  on public.village_admins for select
  to authenticated
  using (user_id = (select auth.uid()));

-- ولا سياسة إدراج: الربط يمرّ من claim_village_admin (تتحقق من الكود).

-- -------------------------- 6.4 فيديوهات القرية --------------------------
-- (1) القراءة عامة: الصفحة عامة والفيديو محتوى مُعلَن — يقرأه الزائر بلا تسجيل
--     دخول، ولا يستطيع تغيير شيئاً (لا سياسة INSERT لـ anon إطلاقاً).
-- (2) الإضافة/التعديل/الحذف: لمسؤولي القرية وحدهم على فيديوهات قريتهم.
--     `drop policy if exists` يبقي إعادة تشغيل السكريبت آمنة كما هو موعود.
drop policy if exists "videos_select_public" on public.videos;
create policy "videos_select_public"
  on public.videos for select
  using (true);

drop policy if exists "videos_modify_admin" on public.videos;
create policy "videos_modify_admin"
  on public.videos for all to authenticated
  using    (village_id = public.current_village_id())
  with check (village_id = public.current_village_id());


-- ============================================================================
-- 7) دوال الواجهة (RPC)
-- ============================================================================
-- 7.1 البحث عن قرية بالكود — متاحة للزائر بلا تسجيل دخول.
--     تُعيد الاسم والكود فقط (لا بيانات أعضاء، ولا أي عمود حسّاس).
create or replace function public.village_lookup(p_code text)
returns table (id uuid, name text, code text)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
begin
  if v_code = '' then
    return;
  end if;

  return query
    select v.id, v.name, v.code
      from public.villages v
     where v.code = v_code
     limit 1;
end;
$$;

comment on function public.village_lookup(text) is 'التحقق من كود القرية قبل فتح نموذج التسجيل (عام)';

-- 7.2 تسجيل عضو جديد — كل التحقق على السيرفر.
--     عمودا الموافقة (`agreed_at` و`terms_version` و`privacy_version`) تُملآن
--     تلقائياً من افتراضاتهما: النموذج لا يقبل الإرسال قبل تفعيل الموافقة.
--     الأخطاء:
--       P0002 ⇒ كود القرية غير معروف
--       P0001 ⇒ بيانات مرفوضة (الرسالة العربية جاهزة للعرض)
--       23505 ⇒ الرقم القومي مسجَّل من قبل (يُفسَّر في الواجهة)
create or replace function public.village_register_member(
  p_code        text,
  p_name        text,
  p_phone       text,
  p_national_id text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code       text := upper(btrim(coalesce(p_code, '')));
  v_name       text := btrim(regexp_replace(coalesce(p_name, ''), '\s+', ' ', 'g'));
  v_phone      text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  v_nid        text := regexp_replace(coalesce(p_national_id, ''), '[^0-9]', '', 'g');
  v_village    uuid;
  v_century    int;
  v_year       int;
  v_birth      date;
  v_age        int;
  v_governor   text;
  v_member_id  uuid;
begin
  -- (أ) القرية ------------------------------------------------------------
  select v.id into v_village
    from public.villages v
   where v.code = v_code;

  if v_village is null then
    raise exception 'كود القرية غير معروف' using errcode = 'P0002';
  end if;

  -- (ب) الاسم -------------------------------------------------------------
  if length(v_name) < 3 then
    raise exception 'اكتب الاسم بالكامل (ثلاثة أحرف على الأقل)' using errcode = 'P0001';
  end if;

  -- (ج) التليفون ----------------------------------------------------------
  if v_phone !~ '^01[0125][0-9]{8}$' then
    raise exception 'رقم التليفون غير صحيح — 11 رقماً يبدأ بـ 010 أو 011 أو 012 أو 015'
      using errcode = 'P0001';
  end if;

  -- (د) الرقم القومي: الصيغة -------------------------------------------------
  if v_nid !~ '^[23][0-9]{13}$' then
    raise exception 'الرقم القومي غير صحيح — 14 رقماً يبدأ بـ 2 أو 3' using errcode = 'P0001';
  end if;

  -- (هـ) تاريخ الميلاد استخراجاً من الرقم (قرن + سنة + شهر + يوم) ------------
  v_century := substring(v_nid from 1 for 1)::int;
  v_year    := (case when v_century = 2 then 1900 else 2000 end)
               + substring(v_nid from 2 for 2)::int;

  begin
    v_birth := make_date(
      v_year,
      substring(v_nid from 4 for 2)::int,
      substring(v_nid from 6 for 2)::int
    );
  exception when others then
    raise exception 'تاريخ الميلاد المستخرج من الرقم غير صحيح' using errcode = 'P0001';
  end;

  if v_birth > current_date then
    raise exception 'تاريخ الميلاد المستخرج من الرقم مستقبلي — راجع الرقم' using errcode = 'P0001';
  end if;

  -- (و) كود المحافظة داخل الرقم -------------------------------------------
  v_governor := substring(v_nid from 8 for 2);
  if v_governor <> all (array[
    '01','02','03','04','11','12','13','14','15','16','17','18','19',
    '21','22','23','24','25','26','27','28','29','31','32','33','34','35','88'
  ]) then
    raise exception 'كود المحافظة داخل الرقم غير معروف' using errcode = 'P0001';
  end if;

  -- (ز) السن ---------------------------------------------------------------
  v_age := date_part('year', age(current_date, v_birth))::int;
  if v_age < 18 then
    raise exception 'التسجيل متاح لمن أتمّ 18 سنة على الأقل' using errcode = 'P0001';
  end if;

  -- (ح) الإدراج — قيد unique على الرقم القومي يرفع 23505 تلقائياً -----------
  insert into public.members (village_id, name, phone, national_id, birth_date, age)
  values (v_village, v_name, v_phone, v_nid, v_birth, v_age)
  returning id into v_member_id;

  return v_member_id;
end;
$$;

comment on function public.village_register_member(text, text, text, text) is 'تسجيل عضو جديد بعد تحقّق كامل من الرقم القومي على السيرفر (عام)';

-- 7.3 ربط حساب مسجَّل بقرية عبر كودها — يُستدعى من تطبيق JoodCraft.
create or replace function public.claim_village_admin(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid     uuid := auth.uid();
  v_village uuid;
  v_code    text := upper(btrim(coalesce(p_code, '')));
begin
  if v_uid is null then
    raise exception 'يجب تسجيل الدخول أولاً' using errcode = 'P0001';
  end if;

  select v.id into v_village
    from public.villages v
   where v.code = v_code;

  if v_village is null then
    raise exception 'كود القرية غير معروف' using errcode = 'P0002';
  end if;

  insert into public.village_admins (user_id, village_id)
  values (v_uid, v_village)
  on conflict (user_id) do update set village_id = excluded.village_id;

  return v_village;
end;
$$;

comment on function public.claim_village_admin(text) is 'ربط حساب JoodCraft المسجَّل بقرية عبر كودها (معتمد على auth.uid)';

-- 7.4 توليد كود قرية جديد: «بادئة لاتينية + السنة» (مثل MAA-2026).
create or replace function public.village_code_from_name(p_prefix text, p_year int default null)
returns text
language sql
stable
as $$
  select substr(
           rpad(upper(regexp_replace(coalesce(p_prefix, ''), '[^A-Za-z]', '', 'g')), 3, 'X'),
           1, 3
         )
         || '-'
         || coalesce(p_year, extract(year from current_date)::int)::text;
$$;

comment on function public.village_code_from_name(text, int) is 'توليد كود قرية بصيغة AAA-YYYY من بادئة لاتينية وسنة';

-- 7.5 حذف بيانات عضو — تنفيذ «حقّ الحذف» الموعود في سياسة الخصوصية.
--     المطابقة على الرقم القومي **ورقم التليفون معاً**، فلا يُحذف صفّ إلا
--     بمن يعرف بياناتَه هو؛ وتعود `false` عند عدم التطابق بدل رفع خطأ،
--     فتعرض الواجهة «لم نجد بيانات متطابقة» بدل رسالة عطل.
--     تطبيع الأرقام هنا كما في `village_register_member`: أي كتابة صحيحة
--     (مسافات أو شرطات أو أرقام عربية-هندية) تصل إلى مطابقة واحدة.
create or replace function public.village_delete_member(
  p_national_id text,
  p_phone text
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nid   text := regexp_replace(coalesce(p_national_id, ''), '[^0-9]', '', 'g');
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  v_count int;
begin
  -- التحقق من التطابق
  delete from public.members
  where national_id = v_nid
    and phone = v_phone;

  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

comment on function public.village_delete_member(text, text) is
  'حقّ الحذف: حذف بيانات عضو بعد مطابقة رقميه القومي والتليفون (متاحة للزائر) — تعود true عند الحذف وfalse عند عدم التطابق';


-- ============================================================================
-- 8) عرض مسطّح لمسؤول القرية (اختياري)
--    security_invoker ⇒ سياسات RLS على الجدول الأصلي تُطبَّق على المستعلِم،
--    فلا يرى المسؤول إلا أعضاء قريته عبر هذا العرض أيضاً.
-- ============================================================================
create or replace view public.village_members_view
with (security_invoker = true)
as
  select m.id,
         m.village_id,
         v.name  as village_name,
         v.code  as village_code,
         m.name,
         m.phone,
         m.national_id,
         m.birth_date,
         m.age,
         m.created_at,
         m.agreed_at,
         m.terms_version,
         m.privacy_version
    from public.members m
    join public.villages v on v.id = m.village_id;

comment on view public.village_members_view is 'قراءة مسطّحة لأعضاء القرية (RLS الأصلية مطبَّقة)';


-- ============================================================================
-- 9) الصلاحيات (مطلوبة لأن RLS تعمل فوق الـ GRANTS)
-- ============================================================================
grant usage on schema public to anon, authenticated;

-- anon: لا وصول لأي جدول — فقط تنفيذ دالتي البحث والتسجيل.
revoke all on public.villages       from anon;
revoke all on public.members        from anon;
revoke all on public.village_admins from anon;

-- authenticated (مسؤول قرية): قراءة/تعديل أعضاء قريته فقط (وفق RLS).
grant select                 on public.villages       to authenticated;
grant select, update, delete on public.members        to authenticated;
grant select                 on public.village_admins to authenticated;
grant select                 on public.village_members_view to authenticated;

-- الفيديوهات: قراءة عامة للزائر (صفحة بلا تسجيل دخول)، وإدارة كاملة لمسؤول
-- القرية على فيديوهات قريته (وفق سياستَي 6.4).
revoke all on public.videos from anon;
grant select                on public.videos to anon;
grant select, insert, update, delete on public.videos to authenticated;

-- الدوال: الواجهة العامة تحتاج ثلاث دوال فقط (البحث والتسجيل والحذف)، والباقي
-- للمسجَّلين.
revoke all on function public.village_register_member(text, text, text, text) from public;
grant execute on function public.village_lookup(text)                 to anon, authenticated;
grant execute on function public.village_register_member(text, text, text, text)
  to anon, authenticated;
grant execute on function public.village_delete_member(text, text)    to anon, authenticated;
grant execute on function public.claim_village_admin(text)            to authenticated;
grant execute on function public.current_village_id()                 to authenticated;
grant execute on function public.is_village_member_of(uuid)           to authenticated;
grant execute on function public.village_code_from_name(text, int)    to authenticated;


-- ============================================================================
-- 10) البذرة — القرية الأولى
--    منشأة الأمراء ومحلة حسن — مركز المحلة الكبرى، محافظة الغربية
-- ============================================================================
insert into public.villages (name, code)
values ('منشأة الأمراء ومحلة حسن', 'MAA-2026')
on conflict (code) do nothing;

-- لربط حساب مسؤول JoodCraft بهذه القرية (نفّذه بعد تسجيل حسابه):
--   select public.claim_village_admin('MAA-2026');
--
-- لإضافة قرية جديدة لاحقاً (بنفس الكود بلا أي تعديل برمجي):
--   insert into public.villages (name, code)
--   values ('اسم القرية', public.village_code_from_name('ABC'));
--   -- ثم اربط مسؤولها:  select public.claim_village_admin('ABC-2026');


-- ============================================================================
-- 11) البذرة — فيديو القرية الأول (اختياري)
--     الإضافة اليدوية المؤقتة: صف واحد في SQL Editor يكفي، ومعرّف الفيديو
--     `youtube_id` يُستخرج آلياً من الرابط إن تُرك فارغاً.
-- ============================================================================
-- insert into public.videos (village_id, title, youtube_url, description)
-- values (
--   (select id from public.villages where code = 'MAA-2026'),
--   'عنوان الفيديو كما يظهر في الصفحة',
--   'https://www.youtube.com/watch?v=XXXXXXXXXXX',
--   'وصف اختياري يظهر أسفل العنوان'
-- );
--
-- لجدولة النشر (يبقى مخفياً حتى موعده):
--   update public.videos
--      set published_at = now() + interval '3 days'
--    where youtube_id = 'XXXXXXXXXXX';
--
-- لعرض فيديوهات القرية وإدارتها:
--   select title, youtube_id, published_at
--     from public.videos
--    order by published_at desc;


-- ============================================================================
-- 12) منصّة المشرف: صاحب المكتب يدير كل القرى من JoodCraft
-- ----------------------------------------------------------------------------
-- جدول تصريح مصغّر: مَن يملك صلاحية «كل القرى». يُضاف الحساب هنا مرة واحدة
-- من SQL Editor بعد إنشائه في Supabase Auth، ومن بعده يفتح «لوحة تحكم
-- القرى» داخل JoodCraft (شاشة دخول بريده وكلمة سره) ويدير كل القرى.
-- ============================================================================
create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

alter table public.platform_admins enable row level security;

-- كل مستخدم مسجَّل يرى صفّ تصريحه هو فقط (لا تُكشف قائمة المشرفين).
drop policy if exists "platform_admins_select_self" on public.platform_admins;
create policy "platform_admins_select_self"
  on public.platform_admins for select
  to authenticated
  using (user_id = (select auth.uid()));

-- هل المستخدم الحالي صاحب المكتب؟ دالة أمان تُستدعى من سياسات RLS ومن اللوحة.
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.platform_admins p
     where p.user_id = auth.uid()
  );
$$;

comment on function public.is_platform_admin() is 'هل المستخدم الحالي مُصرَّح له بإدارة كل القرى (صاحب المكتب)';


-- ============================================================================
-- 13) جدول الإعلانات المحلّية (local_ads)
-- ============================================================================
create table if not exists public.local_ads (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages(id) on delete cascade,
  title text not null,
  image_url text,
  contact_phone text,
  contact_url text,
  starts_at timestamptz default now(),
  ends_at timestamptz,
  is_active boolean default true,
  created_at timestamptz default now()
);

create index if not exists local_ads_village_idx on public.local_ads(village_id);

alter table public.local_ads enable row level security;

-- قراءة عامة: الإعلان النشط محتوى مُعلَن (لا يراه غير النشط أحد).
drop policy if exists "ads_select_public" on public.local_ads;
create policy "ads_select_public" on public.local_ads
  for select using (is_active = true);

-- مسؤول القرية يدير إعلانات قريته وحدها (سياسات مسموحة: تُضمّ لا تُستبدل).
drop policy if exists "ads_modify_admin" on public.local_ads;
create policy "ads_modify_admin" on public.local_ads
  for all to authenticated
  using (village_id = public.current_village_id())
  with check (village_id = public.current_village_id());

-- صاحب المكتب: إعلانات كل القرى (تنضاف إلى سياسة القرية بـ OR).
drop policy if exists "ads_modify_platform" on public.local_ads;
create policy "ads_modify_platform" on public.local_ads
  for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());


-- ============================================================================
-- 14) توسيع RLS: صاحب المكتب يرى ويدير **كل** القرى
-- ----------------------------------------------------------------------------
-- السياسات المسموحة (permissive) تُضمَّ معاً بـ OR: فسياسة القرية الواحدة
-- (current_village_id) تبقى كما هي لمسؤول القرية، وتنضاف إليها سياسة
-- المشرف التي تفتح كل الصفوف على من يملك صفّه في `platform_admins`.
-- ============================================================================
drop policy if exists "villages_manage_platform" on public.villages;
create policy "villages_manage_platform"
  on public.villages for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists "members_platform_admin" on public.members;
create policy "members_platform_admin"
  on public.members for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

drop policy if exists "videos_modify_platform" on public.videos;
create policy "videos_modify_platform"
  on public.videos for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());


-- ============================================================================
-- 15) إحصائيات اللوحة: كل القرى بعداداتها في نداء واحد
--     (عدد المسجَّلين + الفيديوهات + الإعلانات النشطة لكل قرية)
-- ============================================================================
create or replace function public.admin_overview()
returns table (
  village_id       uuid,
  village_name     text,
  village_code     text,
  members_count    bigint,
  videos_count     bigint,
  active_ads_count bigint,
  created_at       timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'هذه الإحصائيات متاحة لصاحب المكتب فقط' using errcode = '42501';
  end if;

  return query
    select v.id,
           v.name,
           v.code,
           (select count(*) from public.members m where m.village_id = v.id),
           (select count(*) from public.videos  d where d.village_id = v.id),
           (select count(*) from public.local_ads a
             where a.village_id = v.id and a.is_active),
           v.created_at
      from public.villages v
     order by v.name;
end;
$$;

comment on function public.admin_overview() is 'إحصائيات كل القرى لشاشة لوحة تحكم صاحب المكتب';


-- ============================================================================
-- 16) تخزين صور الإعلانات (الدلو العام village-ads)
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('village-ads', 'village-ads', true)
on conflict (id) do update set public = excluded.public;

-- قراءة عامة لصور الإعلانات (الإعلان مُعلَن للجميع).
drop policy if exists "village_ads_public_read" on storage.objects;
create policy "village_ads_public_read"
  on storage.objects for select
  using (bucket_id = 'village-ads');

-- الرفع والتعديل والحذف: لصاحب المكتب وحده.
drop policy if exists "village_ads_admin_write" on storage.objects;
create policy "village_ads_admin_write"
  on storage.objects for all to authenticated
  using (bucket_id = 'village-ads' and public.is_platform_admin())
  with check (bucket_id = 'village-ads' and public.is_platform_admin());


-- ============================================================================
-- 17) صلاحيات اللوحة (GRANTS) — RLS هي الحدّ الفعلي، وهذه تفتح البوابة
-- ============================================================================
-- الإعلانات: قراءة عامة للنشط (سياسة 13)، وإدارة كاملة للمسجَّلين ثم RLS
-- تُقصرها على مسؤولي القرى وصاحب المكتب وحدهم.
revoke all on public.local_ads from anon;
grant select                         on public.local_ads to anon;
grant select, insert, update, delete on public.local_ads to authenticated;

-- منصّة المشرف: قراءة صفّ التصريح + صلاحية إنشاء القرى من اللوحة.
grant select                  on public.platform_admins to authenticated;
grant insert, update, delete  on public.villages        to authenticated;

-- دوال اللوحة: لصاحب المكتب المُسجَّل فقط.
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.admin_overview()    to authenticated;

-- لإضافة صاحب المكتب بعد إنشاء حسابه في Supabase Auth (نفّذه من SQL Editor):
--   insert into public.platform_admins (user_id)
--   select id from auth.users where email = 'you@example.com'
--   on conflict do nothing;


-- ============================================================================
-- 18) تطبيق «فرح» — تواصل أهل القرية (نفس المشروع ونفس الجداول)
-- ----------------------------------------------------------------------------
-- الفكرة: كل عضو في `members` يدخل برقم تليفونه **بلا OTP** (كما صُمِّمت صفحة
-- القرية)، فيُستخرج على السيرفر اسمه الكامل ومعرّفه ومعرّف قريته، ثم يتراسل
-- مع أهل قريته بهدوء.
--
-- قواعد الرسائل:
--   * المدعو: 500 حرف في اليوم (مجموع ما يرسله) — ويعود الحدّ غداً.
--   * صاحب الفرح: 100 حرف لكل مدعو (مجموع على المحادثة) بلا حدّ يومي؛ فإذا
--     نفد الحدّ مع مدعو انتهى له وحده، فيرسّل لغيره بحدّه المستقل.
--   * طول الرسالة الواحدة: 100 حرف (قيد على الجدول نفسه).
--
-- الأمان (مبدأ صفحة القرية نفسه):
--   * RLS مُفعّلة على الجداول الثلاثة **بلا أي سياسة** — لا يستطيع أحد
--     قراءتها أو كتابتها مباشرةً، وكل شيء يمرّ حصراً من دوال
--     `security definer` هذه.
--   * ولماذا لا سياسة مثل `farah_messages_select_own`؟ لأن هذا التدفّق **بلا
--     جلسة تسجيل دخول** (`auth.uid()` يعود `null` دائماً)، وجدول `members`
--     ليس فيه عمود `user_id` أصلاً — فالسياسة هناك لا تُترجم، ولو تُرجمت
--     لأغلقت الباب على الجميع. الدالة وحدها تحدّد العضو من تليفونه ولا تعطيه
--     إلا ما يخصّ قريته.
--   * ملاحظة حذف: صفوف الرسائل والتراخيص والعدّاد تتحذّف تلقائياً مع العضو
--     (`on delete cascade`)، فيبقى «حقّ الحذف» في صفحة القرية سليماً.
-- ============================================================================

-- جدول الرسائل — 100 حرف لكل رسالة كحدّ أقصى.
create table if not exists public.farah_messages (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages(id) on delete cascade,
  sender_id uuid not null references public.members(id) on delete cascade,
  receiver_id uuid not null references public.members(id) on delete cascade,
  body text not null check (char_length(body) <= 100),
  created_at timestamptz default now()
);

comment on table  public.farah_messages              is 'رسائل تطبيق «فرح» بين أهل القرية الواحدة (1 إلى 1)';
comment on column public.farah_messages.village_id   is 'قريتها — كل محادثة محصورة في قريتها';
comment on column public.farah_messages.sender_id    is 'المرسل — يتحذّف معه صفّه عند حذف العضو (حقّ الحذف)';
comment on column public.farah_messages.receiver_id  is 'المدعو — يتحذّف معه صفّه عند حذف العضو (حقّ الحذف)';
comment on column public.farah_messages.body         is 'نصّ الرسالة — 100 حرف كحدّ أقصى';

create index if not exists farah_messages_sender_idx on public.farah_messages(sender_id);
create index if not exists farah_messages_receiver_idx on public.farah_messages(receiver_id);
-- مفتاح المحادثة: مرسل ← مدعو بترتيب زمني (لجلب آخر رسالة وسلسلة الرسائل).
create index if not exists farah_messages_pair_idx
  on public.farah_messages(sender_id, receiver_id, created_at desc);

alter table public.farah_messages enable row level security;


-- جدول التراخيص — كود يُوزَّع على صاحب الفرح، ويُفعَّل من داخل التطبيق.
--   * `member_id` يبقى قابلاً للفراغ عمداً: الأكواد تُولَّد مسبقاً في SQL
--     Editor ثم يُطالب بها صاحب الفرح فيفتح صلاحياته لنفسه.
--   * `is_active` تبدأ `false` حتى التفعيل (وإلا كان الكود مفعّلاً قبل
--     أن يدخله أحد).
create table if not exists public.farah_licenses (
  id uuid primary key default gen_random_uuid(),
  village_id uuid not null references public.villages(id) on delete cascade,
  member_id uuid references public.members(id) on delete cascade,
  code text unique not null,
  is_active boolean default false,
  activated_at timestamptz default now(),
  expires_at timestamptz,
  created_at timestamptz default now()
);

comment on table  public.farah_licenses          is 'أكواد تفعيل «صاحب الفرح» — كل كود يمنح صاحله 100 حرف لكل مدعو';
comment on column public.farah_licenses.member_id is 'صاحب الكود — يُملأ عند التفعيل داخل التطبيق';
comment on column public.farah_licenses.code      is 'كود التفعيل كما يكتبه صاحب الفرح (حروف كبيرة بلا مسافات)';

alter table public.farah_licenses enable row level security;


-- جدول عدّاد الرسائل اليومي (لحدّ المدعو: 500 حرف/يوم).
create table if not exists public.farah_daily_counts (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  date date not null default current_date,
  total_chars int default 0,
  unique(member_id, date)
);

comment on table  public.farah_daily_counts            is 'عدّاد أحرف المدعو في كل يوم — أساس حدّ 500 حرف/اليوم';
comment on column public.farah_daily_counts.total_chars is 'مجموع أحرف ما أرسله العضو في هذا اليوم';

alter table public.farah_daily_counts enable row level security;


-- هل يستطيع هذا العضو إرسال هذا العدد من الأحرف؟ (صاحب الفرح ← 100 لكل
-- مدعو، والمدعو ← 500 في اليوم). تُستدعى من `farah_send` على السيرفر وحدها.
create or replace function public.farah_can_send(
  p_sender_id uuid,
  p_receiver_id uuid,
  p_chars int
) returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_daily_total int;
  v_pair_total int;
  v_is_bride_owner boolean;
begin
  -- هل صاحب الفرح؟
  select exists(select 1 from public.farah_licenses
    where member_id = p_sender_id and is_active = true) into v_is_bride_owner;

  if v_is_bride_owner then
    -- صاحب الفرح: 100 حرف لكل مدعو
    select coalesce(sum(char_length(body)), 0) into v_pair_total
    from public.farah_messages
    where sender_id = p_sender_id and receiver_id = p_receiver_id;
    return (v_pair_total + p_chars) <= 100;
  else
    -- المدعو: 500 حرف/يوم
    select coalesce(total_chars, 0) into v_daily_total
    from public.farah_daily_counts
    where member_id = p_sender_id and date = current_date;
    return (coalesce(v_daily_total, 0) + p_chars) <= 500;
  end if;
end;
$$;

comment on function public.farah_can_send(uuid, uuid, int) is
  'هل يكفي حدّ هذا المرسِل؟ (صاحب الفرح 100 حرف/مدعو — المدعو 500 حرف/يوم)';


-- 18.1 الدخول: تحويل تليفون العضو إلى هويّته الكاملة (بلا OTP).
create or replace function public.farah_resolve_member(p_phone text)
returns table (
  member_id uuid,
  full_name text,
  village_id uuid,
  village_name text,
  is_owner boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select m.id,
         m.name,
         m.village_id,
         v.name,
         exists (
           select 1 from public.farah_licenses l
            where l.member_id = m.id and l.is_active
         )
    from public.members m
    join public.villages v on v.id = m.village_id
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;
$$;

comment on function public.farah_resolve_member(text) is
  'دخول «فرح»: تليفون العضو ← اسمه الكامل ومعرّفه وقريته وهل هو صاحب فرح';


-- 18.2 قائمة أهل القرية (بما فيهم صاحب الفرح بعلامة مميّزة).
create or replace function public.farah_members(p_phone text)
returns table (member_id uuid, full_name text, is_owner boolean)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_village uuid;
begin
  select m.village_id into v_village
    from public.members m
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;

  if v_village is null then
    return;
  end if;

  return query
  select m.id,
         m.name,
         exists (
           select 1 from public.farah_licenses l
            where l.member_id = m.id and l.is_active
         )
    from public.members m
   where m.village_id = v_village
   order by m.name;
end;
$$;

comment on function public.farah_members(text) is 'أهل قرية صاحب التليفون — أساس شاشة الرئيسية في تطبيق فرح';


-- 18.3 قائمة المحادثات: كل أهل القرية + آخر رسالة + المتبقي من الحدّ.
create or replace function public.farah_conversations(p_phone text)
returns table (
  partner_id uuid,
  partner_name text,
  partner_is_owner boolean,
  last_body text,
  last_at timestamptz,
  last_from_me boolean,
  remaining int
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_member  uuid;
  v_village uuid;
  v_is_owner boolean;
  v_daily   int;
begin
  select m.id, m.village_id,
         exists (
           select 1 from public.farah_licenses l
            where l.member_id = m.id and l.is_active
         )
    into v_member, v_village, v_is_owner
    from public.members m
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;

  if v_member is null then
    return;
  end if;

  select coalesce(c.total_chars, 0) into v_daily
    from public.farah_daily_counts c
   where c.member_id = v_member and c.date = current_date;

  return query
  with peers as (
    select m.id as pid, m.name as pname
      from public.members m
     where m.village_id = v_village and m.id <> v_member
  ),
  last as (
    select distinct on (case when f.sender_id = v_member then f.receiver_id else f.sender_id end)
           (case when f.sender_id = v_member then f.receiver_id else f.sender_id end) as pid,
           f.body, f.created_at, (f.sender_id = v_member) as from_me
      from public.farah_messages f
     where f.sender_id = v_member or f.receiver_id = v_member
     order by (case when f.sender_id = v_member then f.receiver_id else f.sender_id end),
              f.created_at desc
  ),
  sent as (
    select f.receiver_id as pid, sum(char_length(f.body))::int as total
      from public.farah_messages f
     where f.sender_id = v_member
     group by f.receiver_id
  ),
  owners as (
    select l.member_id as mid
      from public.farah_licenses l
     where l.is_active
  )
  select p.pid,
         p.pname,
         (o.mid is not null),
         l.body,
         l.created_at,
         coalesce(l.from_me, false),
         (case when v_is_owner
               then 100 - coalesce(s.total, 0)
               else 500 - coalesce(v_daily, 0) end)
    from peers p
    left join last l on l.pid = p.pid
    left join sent  s on s.pid = p.pid
    left join owners o on o.mid = p.pid
   order by l.created_at desc nulls last, p.pname;
end;
$$;

comment on function public.farah_conversations(text) is
  'محادثات صاحب التليفون: اسم كل أهل قريته وآخر رسالة والمتبقي من حدّه';


-- 18.4 سلسلة رسائل محادثة واحدة (الأحدث آخرها).
create or replace function public.farah_thread(
  p_phone text,
  p_partner_id uuid,
  p_limit int default 200
)
returns table (id uuid, sender_id uuid, body text, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_member  uuid;
  v_village uuid;
begin
  select m.id, m.village_id into v_member, v_village
    from public.members m
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;

  if v_member is null then
    return;
  end if;

  if not exists (
    select 1 from public.members m
     where m.id = p_partner_id and m.village_id = v_village
  ) then
    raise exception 'هذا المدعو غير موجود في قريتك' using errcode = 'P0002';
  end if;

  return query
  select t.id, t.sender_id, t.body, t.created_at
    from (
      select f.id, f.sender_id, f.body, f.created_at
        from public.farah_messages f
       where (f.sender_id = v_member and f.receiver_id = p_partner_id)
          or (f.sender_id = p_partner_id and f.receiver_id = v_member)
       order by f.created_at desc
       limit greatest(coalesce(p_limit, 200), 1)
    ) t
   order by t.created_at asc;
end;
$$;

comment on function public.farah_thread(text, uuid, int) is
  'رسائل محادثة واحدة بين عضو التليفون ومدعوّه — الأحدث أخيراً للعرض';


-- 18.5 المتبقي من حدّ الإرسال (للمحادثة الحالية).
create or replace function public.farah_allowance(
  p_phone text,
  p_partner_id uuid
)
returns table (remaining int, is_owner boolean)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_member  uuid;
  v_is_owner boolean;
  v_used    int := 0;
begin
  select m.id,
         exists (
           select 1 from public.farah_licenses l
            where l.member_id = m.id and l.is_active
         )
    into v_member, v_is_owner
    from public.members m
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;

  if v_member is null then
    return;
  end if;

  if v_is_owner then
    select coalesce(sum(char_length(f.body)), 0) into v_used
      from public.farah_messages f
     where f.sender_id = v_member and f.receiver_id = p_partner_id;
    remaining := 100 - v_used;
  else
    select coalesce(c.total_chars, 0) into v_used
      from public.farah_daily_counts c
     where c.member_id = v_member and c.date = current_date;
    remaining := 500 - v_used;
  end if;

  return next;
end;
$$;

comment on function public.farah_allowance(text, uuid) is
  'المتبقي من حدّ الإرسال: للمدعو ما تبقّى من 500 حرف اليوم، ولصاحب الفرح ما تبقّى من 100 حرف لهذا المدعو';


-- 18.6 إرسال رسالة — الفحص والإدراج والعدّاد في نداء واحد.
create or replace function public.farah_send(
  p_phone text,
  p_partner_id uuid,
  p_body text
)
returns table (id uuid, body text, created_at timestamptz, remaining int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member    uuid;
  v_village   uuid;
  v_is_owner  boolean;
  v_body      text := btrim(coalesce(p_body, ''));
  v_used      int;
  v_remaining int;
  v_row       public.farah_messages%rowtype;
begin
  -- (أ) هوية العضو من تليفونه --------------------------------------------
  select m.id, m.village_id into v_member, v_village
    from public.members m
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;

  if v_member is null then
    raise exception 'سجّل في صفحة القرية أولاً' using errcode = 'P0002';
  end if;

  -- (ب) المدعو ------------------------------------------------------------
  if p_partner_id is null or p_partner_id = v_member then
    raise exception 'اختر أحد أهل القرية' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.members m
     where m.id = p_partner_id and m.village_id = v_village
  ) then
    raise exception 'هذا المدعو غير موجود في قريتك' using errcode = 'P0002';
  end if;

  -- (ج) طول الرسالة -------------------------------------------------------
  if v_body = '' then
    raise exception 'اكتب رسالتك أولاً' using errcode = 'P0001';
  end if;

  if char_length(v_body) > 100 then
    raise exception 'الرسالة 100 حرف كحدّ أقصى' using errcode = 'P0001';
  end if;

  -- (د) صاحب الفرح؟ -------------------------------------------------------
  select exists (
    select 1 from public.farah_licenses l
     where l.member_id = v_member and l.is_active
  ) into v_is_owner;

  -- (هـ) قفل صفّ العضو: يمنع تجاوز الحدّ بطلبَي إرسال متزامنين -------------
  perform 1 from public.members where id = v_member for update;

  -- (و) الحدود ------------------------------------------------------------
  if not public.farah_can_send(v_member, p_partner_id, char_length(v_body)) then
    if v_is_owner then
      select coalesce(sum(char_length(f.body)), 0) into v_used
        from public.farah_messages f
       where f.sender_id = v_member and f.receiver_id = p_partner_id;
      raise exception 'انتهى حدّ الرسائل لهذا المدعو (بقي % حرف من 100) — راسل مدعواً آخر',
        100 - v_used using errcode = 'P0001';
    end if;

    select coalesce(c.total_chars, 0) into v_used
      from public.farah_daily_counts c
     where c.member_id = v_member and c.date = current_date;
    raise exception 'انتهى حدّ رسائلك اليوم (استخدمت % من 500 حرف) — يتجدد غداً',
      v_used using errcode = 'P0001';
  end if;

  -- (ز) الإدراج -----------------------------------------------------------
  insert into public.farah_messages (village_id, sender_id, receiver_id, body)
  values (v_village, v_member, p_partner_id, v_body)
  returning * into v_row;

  -- (ح) عدّاد المدعو اليومي فقط (صاحب الفرح بلا حدّ يومي) ------------------
  if not v_is_owner then
    insert into public.farah_daily_counts (member_id, date, total_chars)
    values (v_member, current_date, char_length(v_body))
    on conflict (member_id, date)
    do update set total_chars = public.farah_daily_counts.total_chars + excluded.total_chars;
  end if;

  -- (ط) ما تبقّى بعد الإرسال — يُعرض في عدّاد الحقل ------------------------
  if v_is_owner then
    select 100 - coalesce(sum(char_length(f.body)), 0) into v_remaining
      from public.farah_messages f
     where f.sender_id = v_member and f.receiver_id = p_partner_id;
  else
    select 500 - coalesce(c.total_chars, 0) into v_remaining
      from public.farah_daily_counts c
     where c.member_id = v_member and c.date = current_date;
  end if;

  return query select v_row.id, v_row.body, v_row.created_at, coalesce(v_remaining, 0);
end;
$$;

comment on function public.farah_send(text, uuid, text) is
  'إرسال رسالة بعد فحص الحدود (100 حرف للرسالة، و100 لكل مدعو لصاحب الفرح، و500 يومياً للمدعو)';


-- 18.7 تفعيل كود صاحب الفرح.
create or replace function public.farah_activate(p_phone text, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_member   uuid;
  v_village  uuid;
  v_code     text := upper(btrim(coalesce(p_code, '')));
  v_license  public.farah_licenses%rowtype;
begin
  select m.id, m.village_id into v_member, v_village
    from public.members m
   where m.phone = regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g')
   limit 1;

  if v_member is null then
    raise exception 'سجّل في صفحة القرية أولاً' using errcode = 'P0002';
  end if;

  if v_code = '' then
    raise exception 'اكتب كود التفعيل' using errcode = 'P0001';
  end if;

  select * into v_license
    from public.farah_licenses l
   where l.code = v_code
   for update;

  if not found then
    raise exception 'كود التفعيل غير صحيح — راجع الكود مع مكتب القرية'
      using errcode = 'P0001';
  end if;

  if v_license.village_id <> v_village then
    raise exception 'هذا الكود لا يخصّ قريتك' using errcode = 'P0001';
  end if;

  if v_license.member_id is not null and v_license.member_id <> v_member then
    raise exception 'هذا الكود مُفعَّل لعضو آخر' using errcode = 'P0001';
  end if;

  update public.farah_licenses
     set member_id = v_member,
         is_active = true,
         activated_at = now()
   where id = v_license.id;

  return true;
end;
$$;

comment on function public.farah_activate(text, text) is
  'تفعيل كود صاحب الفرح: يمنح صاحبه 100 حرف لكل مدعو بلا حدّ يومي';

-- صلاحيات تطبيق «فرح» — دواله العامة فقط، والجداول مغلقة (RLS بلا سياسة).
revoke all on public.farah_messages       from public, anon, authenticated;
revoke all on public.farah_licenses       from public, anon, authenticated;
revoke all on public.farah_daily_counts   from public, anon, authenticated;

grant execute on function public.farah_resolve_member(text)  to anon, authenticated;
grant execute on function public.farah_members(text)         to anon, authenticated;
grant execute on function public.farah_conversations(text)   to anon, authenticated;
grant execute on function public.farah_thread(text, uuid, int)   to anon, authenticated;
grant execute on function public.farah_allowance(text, uuid)     to anon, authenticated;
grant execute on function public.farah_send(text, uuid, text)    to anon, authenticated;
grant execute on function public.farah_activate(text, text)      to anon, authenticated;

-- توليد أكواد تفعيل لأصحاب الأفراح (من SQL Editor):
-- insert into public.farah_licenses (village_id, code)
-- values ((select id from public.villages where code = 'MAA-2026'), 'FARAH-0001');


-- ============================================================================
-- 19) تحقّق سريع (اختياري — يُعرض في SQL Editor)
-- ============================================================================
-- select tablename, rowsecurity from pg_tables where schemaname = 'public' order by tablename;
-- select schemaname, tablename, policyname, cmd, roles from pg_policies
--   where schemaname = 'public' order by tablename, policyname;
-- select * from public.villages;
-- select count(*) from public.members;
-- يجب أن يعود فارغاً بعد تشغيل المقطع 2.1 (رقم قومي واحد = شخص واحد):
-- select national_id, count(*) from public.members
--   group by national_id having count(*) > 1;
-- select count(*) from public.videos;
-- select * from public.local_ads;
-- select * from public.platform_admins;
-- select * from public.admin_overview();
-- select * from public.farah_licenses;
-- select * from public.farah_messages order by created_at desc limit 20;
-- select public.farah_resolve_member('01012345678');
-- select public.farah_can_send(<member-uuid>, <receiver-uuid>, 10);

-- ✅ نهاية تأسيس قاعدة بيانات صفحة القرية.


-- ============================================================================
-- 20) لوحة تحكم المالك (owner_admin) — إدارة القرى والتراخيص من داخل JoodCraft
-- ----------------------------------------------------------------------------
-- صاحب المنصّة وحده (صفّه في `platform_admins`) يقرأ ويُنشئ ويعدّل ويحذف.
-- كل دالة هنا `security definer` وتبدأ بفحص `is_platform_admin()` فتبقى
-- الحماية في القاعدة نفسها وإن سقطت أي سياسة RLS. معاملات الدوال بالبادئة
-- `p_` كبقية دوال الملف، ومنطقها المقابل: (name_ar, name_en, gov, center,
-- postal, plus_code) و(village_id, name, phone, months).
-- ============================================================================

-- 20.1 أعمدة لوحة المالك على القرى: الاسم اللاتيني والمحافظة والمركز.
alter table public.villages
  add column if not exists name_en     text,
  add column if not exists governorate text,
  add column if not exists center      text;

comment on column public.villages.name_en     is 'الاسم اللاتيني — أساس بادئة الكود المولَّد';
comment on column public.villages.governorate is 'المحافظة — تُملأ من لوحة تحكم المالك';
comment on column public.villages.center      is 'المركز/القسم — تُملأ من لوحة تحكم المالك';

-- 20.2 بيانات المشترك على تراخيص فرح: مُصدر + مشترك + مدة.
alter table public.farah_licenses
  add column if not exists subscriber_name  text,
  add column if not exists subscriber_phone text,
  add column if not exists issued_by       uuid default auth.uid(),
  add column if not exists months           int;

comment on column public.farah_licenses.subscriber_name  is 'اسم صاحب المكتب المشترِك — من لوحة تحكم المالك';
comment on column public.farah_licenses.subscriber_phone is 'تليفون صاحب المكتب — من لوحة تحكم المالك';
comment on column public.farah_licenses.issued_by        is 'مَن أصدر الترخيص (حساب المالك)';
comment on column public.farah_licenses.months           is 'مدة الترخيص بالأشهر (1 أو 3 أو 12)';

-- 20.3 توسيع صيغة الكود: الصيغة القديمة `AAA-YYYY` + صيغة لوحة المالك
--     `بادئة-بريد-Plus مختصر` مثل MAA-31951-25GF (أو MAA-02026-26MA عند
--     غياب الرمز البريدي) — نفس صيغتَي `VillageCode.pattern` في التطبيق.
alter table public.villages drop constraint if exists villages_code_format;
alter table public.villages add constraint villages_code_format check (
  code ~ '^[A-Z]{3}-[0-9]{4}$'
  or code ~ '^[A-Z]{3}-[0-9]{5}-[A-Z0-9]{4,6}$'
);

-- 20.4 قراءة التراخيص للمالك وحده: الجدول مُغلق بـ`revoke` في القسم 17،
--     فنعيد المنح مقروءاً هنا + سياسة RLS تُبقي الصفوف عند المالك.
grant select on public.farah_licenses to authenticated;
drop policy if exists "licenses_select_platform" on public.farah_licenses;
create policy "licenses_select_platform"
  on public.farah_licenses for select to authenticated
  using (public.is_platform_admin());

-- 20.5 توليد كود قرية وإنشاؤها في خطوة واحدة — يعيد الكود المولَّد.
--     البادئة من أولى حروف الاسم اللاتيني (padRight X إلى 3)، والبريد خمسة
--     أرقام (بديله «0 + السنة» مثل 02026)، وPlus Code مختصر الجزء القبلي
--     لعلامة `+` (مثل 25GF من 25GF+PQ) وبديله سنتان + حرفان من الاسم.
--     التكرار بين قريتين يُحلّ بإضافة رقم محاولة إلى آخر جزء حتى 99.
create or replace function public.owner_generate_village_code(
  p_name_ar   text,
  p_name_en   text,
  p_gov       text,
  p_center    text,
  p_postal    text default null,
  p_plus_code text default null
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefix text;
  v_postal text;
  v_plus   text;
  v_base   text;
  v_code   text;
  v_try    int := 0;
begin
  if not public.is_platform_admin() then
    raise exception 'غير مصرَّح: هذه الدالة لصاحب المنصّة فقط';
  end if;
  if coalesce(btrim(p_name_ar), '') = '' then
    raise exception 'اسم القرية مطلوب';
  end if;

  -- البادئة: حروف الاسم اللاتيني كبيرة، تُقصّ إلى 3 وتُملأ بـX.
  v_prefix := substr(
    rpad(upper(regexp_replace(coalesce(p_name_en, ''), '[^A-Za-z]', '', 'g')), 3, 'X'),
    1, 3
  );

  -- الرمز البريدي: خمسة أرقام كما في الرموز المصرية؛ إن خالف فبديل
  -- «0 + السنة» (02026) — بيدوم الكود الصيغة الجديدة دوماً، وهي الصيغة
  -- الوحيدة التي تقبلها `VillageCode.pattern` الموسّعة في التسجيل.
  v_postal := regexp_replace(coalesce(p_postal, ''), '[^0-9]', '', 'g');
  if length(v_postal) <> 5 then
    v_postal := '0' || to_char(current_date, 'YYYY');
  end if;

  -- Plus Code مختصر: الجزء القبلي لعلامة +؛ إن غاب أو قصر فسنتان + حرفان.
  v_plus := upper(regexp_replace(coalesce(p_plus_code, ''), '[^0-9A-Za-z+]', '', 'g'));
  if position('+' in v_plus) > 0 then
    v_plus := split_part(v_plus, '+', 1);
  end if;
  v_plus := substr(v_plus, 1, 4);
  if length(v_plus) < 4 then
    v_plus := substr(
      to_char(current_date, 'YY')
        || upper(regexp_replace(coalesce(p_name_en, ''), '[^A-Za-z]', '', 'g')),
      1, 4
    );
  end if;
  v_plus := rpad(v_plus, 4, 'Q');

  v_base := v_prefix || '-' || v_postal || '-' || v_plus;
  v_code := v_base;
  while exists (select 1 from public.villages v where v.code = v_code) loop
    v_try := v_try + 1;
    if v_try > 99 then
      raise exception 'تعذّر توليد كود فريد — جرّب رمزاً بريدياً أو Plus Code آخر';
    end if;
    v_code := v_base || v_try::text;
  end loop;

  insert into public.villages (name, name_en, code, governorate, center)
  values (
    btrim(p_name_ar),
    nullif(btrim(p_name_en), ''),
    v_code,
    nullif(btrim(p_gov), ''),
    nullif(btrim(p_center), '')
  );

  return v_code;
end;
$$;

comment on function public.owner_generate_village_code(text, text, text, text, text, text) is
  'لوحة المالك: توليد كود قرية (بادئة + بريد + Plus مختصر) وإنشاؤها — يعيد الكود المولَّد';

-- 20.6 إصدار ترخيص «صاحب الفرح» بصيغة FRH-<بادئة القرية>-<تسلسل 3 أرقام>
--     مثل FRH-MAA-001 — والتسلسل يتقدّم تلقائياً عند التكرار حتى 999.
create or replace function public.owner_create_license(
  p_village_id uuid,
  p_name       text,
  p_phone      text,
  p_months     int
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_village_code text;
  v_prefix       text;
  v_seq          int := 1;
  v_code         text;
begin
  if not public.is_platform_admin() then
    raise exception 'غير مصرَّح: هذه الدالة لصاحب المنصّة فقط';
  end if;
  if coalesce(btrim(p_name), '') = '' then
    raise exception 'اسم صاحب المكتب مطلوب';
  end if;
  if p_months not in (1, 3, 12) then
    raise exception 'المدة المسموحة: شهر أو 3 شهور أو سنة';
  end if;

  select v.code into v_village_code from public.villages v where v.id = p_village_id;
  if v_village_code is null then
    raise exception 'القرية غير موجودة';
  end if;

  v_prefix := split_part(v_village_code, '-', 1);
  loop
    v_code := 'FRH-' || v_prefix || '-' || lpad(v_seq::text, 3, '0');
    exit when not exists (select 1 from public.farah_licenses l where l.code = v_code);
    v_seq := v_seq + 1;
    if v_seq > 999 then
      raise exception 'امتُلئت تسلسلات بادئة ' || v_prefix;
    end if;
  end loop;

  insert into public.farah_licenses
    (village_id, code, subscriber_name, subscriber_phone, issued_by, months, expires_at)
  values (
    p_village_id,
    v_code,
    nullif(btrim(p_name), ''),
    nullif(btrim(p_phone), ''),
    auth.uid(),
    p_months,
    now() + make_interval(months => p_months)
  );

  return v_code;
end;
$$;

comment on function public.owner_create_license(uuid, text, text, int) is
  'لوحة المالك: إصدار ترخيص صاحب الفرح FRH-<بادئة>-<تسلسل> بمدة 1/3/12 شهراً — يعيد الكود';

grant execute on function public.owner_generate_village_code(text, text, text, text, text, text)
  to authenticated;
grant execute on function public.owner_create_license(uuid, text, text, int)
  to authenticated;

-- 20.7 قراءة التراخيص في نداء واحد: `owner_list_licenses()` تُرجع كل تراخيص
--     «صاحب الفرح» باسم قريتها ومدة المدة المتبقية، للمالك وحده.
--
-- لماذا دالة لا `select` مباشر؟ لأن القراءة المباشرة تحتاج منحة `select` على
-- الجدول + سياسة RLS (20.4)، وكلاهما قد يُشغَّل في مشروع ولا يُشغَّل في آخر؛
-- والدالة `security definer` تفحص `is_platform_admin()` بنفسها فتبقى الحماية
-- في القاعدة مهما حدث لسياسة RLS.
--
-- ملاحظة على العميل: `SupabaseOwnerAdminRepository` يقرأ من الجدول مباشرةً
-- (أغنى الأعمدة ثم الأصلية) لأنه يعمل على كل صور القاعدة؛ وهذه الدالة بديل
-- جاهز لمن يفضّل نداءً واحداً — أو للتشخيص من SQL Editor:
--   select * from public.owner_list_licenses();
create or replace function public.owner_list_licenses()
returns table (
  id               uuid,
  code             text,
  village_id       uuid,
  village_name     text,
  subscriber_name  text,
  subscriber_phone text,
  months           int,
  is_active        boolean,
  created_at       timestamptz,
  expires_at       timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select l.id,
         l.code,
         l.village_id,
         v.name,
         l.subscriber_name,
         l.subscriber_phone,
         l.months,
         l.is_active,
         l.created_at,
         l.expires_at
    from public.farah_licenses l
    left join public.villages v on v.id = l.village_id
   where public.is_platform_admin()
   order by l.created_at desc;
$$;

comment on function public.owner_list_licenses() is
  'لوحة المالك: كل تراخيص صاحب الفرح مع أسماء القرى — للمالك وحده (is_platform_admin)';

grant execute on function public.owner_list_licenses() to authenticated;

-- ✅ نهاية إضافات لوحة تحكم المالك.
