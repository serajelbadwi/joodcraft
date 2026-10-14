-- ============================================================================
-- JoodCraft — نظام «النطاقات» (Domains)
-- ----------------------------------------------------------------------------
-- «النطاق» هو الاسم الجديد لـ«القرية»: وحدة عزل واحدة لها كود تسجيل فريد.
--
-- الفهرس:
--   1) جدول public.domains — النطاقات
--   2) تطبيع وفحص صيغة الكود
--   3) Row Level Security — القراءة للمنصّة والإدارة للدوال
--   4) owner_generate_domain_code — توليد الكود وإنشاء النطاق في خطوة واحدة
--
-- الصيغة المولَّدة: MAA-31951-25GF989
--   * MAA    — بادئة 3 حروف من الاسم الإنجليزي (تُقصّ/تُحشى بـX)
--   * 31951  — الرمز البريدي (5 أرقام؛ بديله «0 + السنة» مثل 02026)
--   * 25GF989 — 4 أحرف قبل علامة + في Plus Code + 3 أحرف بعدها
--               (بديل قصير: سنتان + حرفان؛ ثم حشو بـQ)
--
-- الخوارزمية مطابقة حرفياً لـ `DomainCodeGenerator` في
-- `lib/features/domain/domain/domain_code_generator.dart`.
--
-- التشغيل: Supabase SQL Editor، ثم ضع مالك المنصّة في `platform_admins`
-- (يُنشئه قسم لوحة المالك في `supabase_village.sql`).
-- idempotent: التشغيل أكثر من مرة آمن (create if not exists / or replace).
-- ============================================================================


-- ============================================================================
-- 1) جدول public.domains — النطاقات
--    الكود هو مفتاح التسجيل الموزَّع، وهو فريد لكل نطاق.
-- ============================================================================
create table if not exists public.domains (
  id           uuid        primary key default gen_random_uuid(),
  name_ar      text        not null,
  name_en      text        not null,
  governorate  text,
  center       text,
  postal_code  text,
  plus_code    text,
  latitude     double precision,
  longitude    double precision,
  code         text        not null,
  created_at   timestamptz not null default now(),
  constraint domains_name_ar_not_blank check (length(btrim(name_ar)) > 0),
  constraint domains_code_format check (
    code ~ '^[A-Z]{3}-[0-9]{5}-[A-Z0-9]{4,7}$'
  ),
  constraint domains_code_unique unique (code),
  -- الإحداثيات مدى الأرض المعقول (يسمح بـnull: بلا خريطة).
  constraint domains_lat_range check (latitude is null
    or (latitude between -90 and 90)),
  constraint domains_lng_range check (longitude is null
    or (longitude between -180 and 180))
);

comment on table  public.domains       is 'نطاقات المبادرة — كل نطاق كود تسجيل فريد يُوزَّع على أهله';
comment on column public.domains.code        is 'كود التسجيل: بادئة-رمز بريدي-Plus Code (MAA-31951-25GF989)';
comment on column public.domains.name_en     is 'الاسم اللاتيني — أساس بادئة الكود المولَّد';
comment on column public.domains.governorate is 'المحافظة — من لوحة الإدارة';
comment on column public.domains.center      is 'المركز/القسم — من لوحة الإدارة';
comment on column public.domains.postal_code is 'الرمز البريدي (5 أرقام) — مدخل الكود';
comment on column public.domains.plus_code   is 'Google Plus Code كما كُتب — مدخل الكود';
comment on column public.domains.latitude    is 'خط العرض — للخريطة (اختياري)';
comment on column public.domains.longitude   is 'خط الطول — للخريطة (اختياري)';

create index if not exists domains_code_idx     on public.domains (code);
create index if not exists domains_name_ar_idx  on public.domains (name_ar);
create index if not exists domains_governorate_idx on public.domains (governorate);


-- ============================================================================
-- 2) تطبيع الكود والاسم قبل أي إدراج أو تعديل — (حروف كبيرة، بلا مسافات
--    زائدة) على غرار `villages_normalize_code`.
-- ============================================================================
create or replace function public.domains_normalize_fields()
returns trigger
language plpgsql
as $$
begin
  new.code        := upper(btrim(new.code));
  new.name_ar     := btrim(new.name_ar);
  new.name_en     := btrim(new.name_en);
  new.governorate := nullif(btrim(coalesce(new.governorate, '')), '');
  new.center      := nullif(btrim(coalesce(new.center, '')), '');
  new.postal_code := nullif(btrim(coalesce(new.postal_code, '')), '');
  new.plus_code   := nullif(btrim(coalesce(new.plus_code, '')), '');
  -- إحداثي (0,0) بلا بقية بيانات ⇒ غير محدد: يُخزَّن null.
  if new.latitude = 0 and new.longitude = 0 then
    new.latitude  := null;
    new.longitude := null;
  end if;
  return new;
end;
$$;

drop trigger if exists domains_normalize_fields_trg on public.domains;
create trigger domains_normalize_fields_trg
  before insert or update on public.domains
  for each row execute function public.domains_normalize_fields();


-- ============================================================================
-- 3) Row Level Security
--    القراءة للمنصّة (platform_admins) والإدارة عبر الدوال وحدها — لا مسار
--    كتابة من الواجهة.
-- ============================================================================
alter table public.domains enable row level security;

revoke all on public.domains from anon;

drop policy if exists "domains_select_platform" on public.domains;
create policy "domains_select_platform"
  on public.domains for select
  to authenticated
  using (public.is_platform_admin());

-- لا سياسة إدراج/تعديل/حذف: الإدارة كلها عبر
-- `owner_generate_domain_code` وما يستدعيه من دوال، فلا يعدّل أي حساب
-- نطاقاً أو كوده من الواجهة مباشرة.
grant select on public.domains to authenticated;


-- ============================================================================
-- 4) توليد كود نطاق وإنشائه في خطوة واحدة — يعيد الكود المولَّد.
--
--    * البادئة: حروف الاسم الإنجليزي كبيرة، تُقصّ إلى 3 وتُملأ بـX.
--    * الرمز البريدي: خمسة أرقام؛ بديله «0 + السنة» (02026).
--    * الجزء الأخير: 4 أحرف قبل علامة + في Plus Code و3 بعدها (25GF+989
--      ⇒ 25GF989)؛ بديل قصير: سنتان + حرفان (26MA)؛ ثم حشو بـQ إلى 4.
--    * التكرار يُحلّ بإضافة رقم محاولة إلى آخر جزء حتى 99.
-- ============================================================================
create or replace function public.owner_generate_domain_code(
  p_name_ar   text,
  p_name_en   text,
  p_gov       text,
  p_center    text,
  p_postal    text default null,
  p_plus_code text default null,
  p_lat       double precision default null,
  p_lng       double precision default null
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefix text;
  v_postal text;
  v_head   text;
  v_tail   text;
  v_local  text;
  v_base   text;
  v_code   text;
  v_try    int := 0;
begin
  if not public.is_platform_admin() then
    raise exception 'غير مصرَّح: هذه الدالة لصاحب المنصّة فقط';
  end if;
  if coalesce(btrim(p_name_ar), '') = '' then
    raise exception 'اسم النطاق مطلوب';
  end if;

  -- البادئة: حروف الاسم اللاتيني كبيرة، تُقصّ إلى 3 وتُملأ بـX.
  v_prefix := substr(
    rpad(upper(regexp_replace(coalesce(p_name_en, ''), '[^A-Za-z]', '', 'g')), 3, 'X'),
    1, 3
  );

  -- الرمز البريدي: خمسة أرقام؛ إن خالف فبديل «0 + السنة».
  v_postal := regexp_replace(coalesce(p_postal, ''), '[^0-9]', '', 'g');
  if length(v_postal) <> 5 then
    v_postal := '0' || to_char(current_date, 'YYYY');
  end if;

  -- الجزء الأخير: 4 أحرف قبل علامة + و3 بعدها.
  v_head := regexp_replace(coalesce(p_plus_code, ''), '[^0-9A-Za-z+]', '', 'g');
  v_head := upper(v_head);
  if position('+' in v_head) > 0 then
    v_tail := substr(split_part(v_head, '+', 2), 1, 3);
    v_head := split_part(v_head, '+', 1);
  else
    v_tail := '';
  end if;
  v_head := substr(v_head, 1, 4);

  v_local := substr(v_head || v_tail, 1, 7);
  if length(v_local) < 4 then
    -- البديل: سنتان + حرفان من الاسم اللاتيني.
    v_local := substr(
      to_char(current_date, 'YY')
        || upper(regexp_replace(coalesce(p_name_en, ''), '[^A-Za-z]', '', 'g')),
      1, 4
    );
  end if;
  v_local := rpad(v_local, 4, 'Q');

  v_base := v_prefix || '-' || v_postal || '-' || v_local;
  v_code := v_base;
  while exists (select 1 from public.domains d where d.code = v_code) loop
    v_try := v_try + 1;
    if v_try > 99 then
      raise exception 'تعذّر توليد كود فريد — جرّب رمزاً بريدياً أو Plus Code آخر';
    end if;
    v_code := v_base || v_try::text;
  end loop;

  insert into public.domains (
    name_ar, name_en, code, governorate, center,
    postal_code, plus_code, latitude, longitude
  )
  values (
    btrim(p_name_ar),
    nullif(btrim(p_name_en), ''),
    v_code,
    nullif(btrim(p_gov), ''),
    nullif(btrim(p_center), ''),
    nullif(btrim(coalesce(p_postal, '')), ''),
    nullif(btrim(coalesce(p_plus_code, '')), ''),
    nullif(p_lat, 0),
    nullif(p_lng, 0)
  );

  return v_code;
end;
$$;

comment on function public.owner_generate_domain_code(text, text, text, text, text, text, double precision, double precision) is
  'لوحة الإدارة: توليد كود نطاق (بادئة + رمز بريدي + Plus Code) وإنشاؤه — يعيد الكود المولَّد';

grant execute on function public.owner_generate_domain_code(
  text, text, text, text, text, text, double precision, double precision
) to authenticated;
revoke execute on function public.owner_generate_domain_code(
  text, text, text, text, text, text, double precision, double precision
) from public, anon;
