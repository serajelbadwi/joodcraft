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
  constraint members_nid_unique       unique (national_id),
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

-- الدوال: الواجهة العامة تحتاج دالتين فقط، والباقي للمسجَّلين.
revoke all on function public.village_register_member(text, text, text, text) from public;
grant execute on function public.village_lookup(text)                 to anon, authenticated;
grant execute on function public.village_register_member(text, text, text, text)
  to anon, authenticated;
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
-- 18) تحقّق سريع (اختياري — يُعرض في SQL Editor)
-- ============================================================================
-- select tablename, rowsecurity from pg_tables where schemaname = 'public' order by tablename;
-- select schemaname, tablename, policyname, cmd, roles from pg_policies
--   where schemaname = 'public' order by tablename, policyname;
-- select * from public.villages;
-- select count(*) from public.members;
-- select count(*) from public.videos;
-- select * from public.local_ads;
-- select * from public.platform_admins;
-- select * from public.admin_overview();

-- ✅ نهاية تأسيس قاعدة بيانات صفحة القرية.
