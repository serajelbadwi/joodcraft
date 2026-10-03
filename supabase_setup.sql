-- ============================================================================
--  JoodCraft — Phase 1 Database Bootstrap
--  ملف تأسيس قاعدة بيانات Supabase لمنصة جودكرافت (الشهادات والعقود الرسمية)
-- ----------------------------------------------------------------------------
--  طريقة التنفيذ:
--    1) Supabase Dashboard  ->  SQL Editor  ->  New query
--    2) الصق محتوى هذا الملف بالكامل ثم اضغط Run
--  السكريبت Idempotent — يمكن إعادة تشغيله بأمان دون فقدان بيانات.
-- ----------------------------------------------------------------------------
--  مبدأ الأمان: كل جدول محمي بـ Row Level Security، ولا يمكن لأي مستخدم
--  قراءة أو تعديل أي صف لا يملكه (لم يُنشئه user_id = auth.uid()).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0) ملحقات مساعدة
-- ---------------------------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";


-- ============================================================================
-- 1) جدول public.profiles — ملف المستخدم
--    مرتبط بـ auth.users على مستوى المفتاح الأساسي (1:1)
-- ============================================================================
create table if not exists public.profiles (
  id                uuid        primary key references auth.users (id) on delete cascade,
  full_name         text,
  organization_name text,
  subscription_tier text        not null default 'free'
                                check (subscription_tier in ('free', 'pro', 'enterprise')),
  created_at        timestamptz not null default now()
);

comment on table  public.profiles                  is 'الملف التعريفي للمستخدم — سجل واحد لكل مستخدم في auth.users';
comment on column public.profiles.subscription_tier is 'مستوى الاشتراك: free | pro | enterprise';


-- ============================================================================
-- 2) جدول public.templates — قوالب الشهادات والعقود
--    كيان مستقل مرتبط بـ user_id (قابل لإعادة الاستخدام في كل المشاريع)
-- ============================================================================
create table if not exists public.templates (
  id            uuid        primary key default gen_random_uuid(),
  user_id       uuid        not null references auth.users (id) on delete cascade,
  title         text        not null,
  category      text        not null check (category    in ('certificate', 'contract')),
  orientation   text        not null check (orientation in ('landscape', 'portrait')),
  -- layout_data: هيكل التصميم الكامل (عناصر، إحداثيات، خطوط، ألوان، ربط حقول)
  -- schema_version إلزامي من اليوم الأول لتمكين ترحيل القوالب لاحقاً.
  layout_data   jsonb       not null default jsonb_build_object(
                              'schema_version', 1,
                              'canvas', jsonb_build_object('width', 1123, 'height', 794, 'unit', 'pt'),
                              'elements', '[]'::jsonb
                            ),
  is_public     boolean     not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint templates_title_not_blank check (length(btrim(title)) > 0),
  constraint templates_layout_is_object check (jsonb_typeof(layout_data) = 'object'),
  -- فرض وجود schema_version داخل الـ JSON (تحصين ضد قوالب بلا إصدار)
  constraint templates_layout_has_schema_version
    check (layout_data ? 'schema_version')
);

comment on table  public.templates               is 'قوالب الشهادات (Landscape) والعقود (Portrait) الخاصة بالمستخدم';
comment on column public.templates.layout_data   is 'JSON Layout — يحتوي إلزامياً على schema_version لترحيل الإصدارات';
comment on column public.templates.is_public     is 'مشاركة القالب للعموم (قراءة فقط) — يغذّي مكتبة القوالب في المرحلة 5';

create index if not exists templates_user_id_idx     on public.templates (user_id);
create index if not exists templates_category_idx    on public.templates (category, orientation);
create index if not exists templates_updated_at_idx  on public.templates (updated_at desc);


-- ============================================================================
-- 3) جدول public.user_assets — الأصول المرفوعة (شعار / توقيع / ختم / إطار)
-- ============================================================================
create table if not exists public.user_assets (
  id         uuid        primary key default gen_random_uuid(),
  user_id    uuid        not null references auth.users (id) on delete cascade,
  asset_name text        not null,
  asset_type text        not null check (asset_type in ('logo', 'signature', 'stamp', 'border')),
  file_url   text        not null,
  created_at timestamptz not null default now(),
  constraint user_assets_name_not_blank check (length(btrim(asset_name)) > 0)
);

comment on table  public.user_assets            is 'أصول المستخدم (شعار/توقيع/ختم/إطار) المخزّنة في Supabase Storage';
comment on column public.user_assets.file_url   is 'المسار داخل bucket: user-assets/{user_id}/{filename}';

create index if not exists user_assets_user_id_idx on public.user_assets (user_id, asset_type);


-- ============================================================================
-- 4) الدوال والمشغلات (Triggers)
-- ============================================================================

-- 4.1) إنشاء سجل profiles تلقائياً فور تسجيل مستخدم جديد في auth.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, organization_name)
  values (
    new.id,
    -- يدعم تمرير الاسم من واجهة التسجيل عبر options.data
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.raw_user_meta_data ->> 'organization_name'
  )
  on conflict (id) do nothing;   -- حماية من التكرار (backfill / re-registration)
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- 4.2) تحديث updated_at تلقائياً عند أي تعديل على القوالب
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_templates_updated on public.templates;
create trigger on_templates_updated
  before update on public.templates
  for each row execute function public.handle_updated_at();


-- 4.3) مزامنة الاسم/المؤسسة من metadata عند تأكيد البريد (اختياري — يبقى آمن الإعادة)
create or replace function public.sync_profile_from_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
     set full_name         = coalesce(nullif(btrim(coalesce(new.raw_user_meta_data ->> 'full_name', '')), ''), full_name),
         organization_name = coalesce(nullif(btrim(coalesce(new.raw_user_meta_data ->> 'organization_name', '')), ''), organization_name)
   where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
  after update of raw_user_meta_data on auth.users
  for each row execute function public.sync_profile_from_auth();


-- ============================================================================
-- 5) تفعيل RLS على كل الجداول (الوضع الافتراضي = منع كل شيء)
-- ============================================================================
alter table public.profiles    enable row level security;
alter table public.templates   enable row level security;
alter table public.user_assets enable row level security;

-- ملاحظة هندسية مهمة (لا تحذف):
--   نحن **لا** نستخدم FORCE ROW LEVEL SECURITY هنا بشكل متعمد.
--   السبب: مشغّل `handle_new_user` هو SECURITY DEFINER ويعمل بهوية مالك الجدول
--   (postgres)، ولو فُرضت RLS على المالك لتوقّف insert داخل الـ trigger لأن
--   auth.uid() تكون null لحظة التسجيل → سيفشل تسجيل المستخدم بالكامل.
--   بدون FORCE: المالك (postgres/SQL Editor) يتجاوز RLS، بينما anon و
--   authenticated يخضعان للسياسات أدناه بالكامل — وهو المطلوب أمنياً.


-- ============================================================================
-- 6) سياسات الوصول — كل مستخدم يرى ويعدّل بياناته الخاصة فقط
-- ============================================================================

-- ---------------------------- 6.1 profiles --------------------------------
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (id = (select auth.uid()));

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- لا سياسة DELETE: حذف الملف التعريفي يتم فقط عبر حذف حساب auth.users (CASCADE).


-- ---------------------------- 6.2 templates -------------------------------
-- القراءة: قوالبي + القوالب العامة (is_public) بصيغة قراءة فقط.
-- ملاحظة: لو أردت حصراً صارماً على مالك البيانات فقط، احذف السطر
--         `or is_public = true` من السياسة التالية.
drop policy if exists "templates_select_own_or_public" on public.templates;
create policy "templates_select_own_or_public"
  on public.templates for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or is_public = true
  );

drop policy if exists "templates_insert_own" on public.templates;
create policy "templates_insert_own"
  on public.templates for insert
  to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "templates_update_own" on public.templates;
create policy "templates_update_own"
  on public.templates for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "templates_delete_own" on public.templates;
create policy "templates_delete_own"
  on public.templates for delete
  to authenticated
  using (user_id = (select auth.uid()));


-- --------------------------- 6.3 user_assets ------------------------------
drop policy if exists "user_assets_select_own" on public.user_assets;
create policy "user_assets_select_own"
  on public.user_assets for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "user_assets_insert_own" on public.user_assets;
create policy "user_assets_insert_own"
  on public.user_assets for insert
  to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists "user_assets_update_own" on public.user_assets;
create policy "user_assets_update_own"
  on public.user_assets for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "user_assets_delete_own" on public.user_assets;
create policy "user_assets_delete_own"
  on public.user_assets for delete
  to authenticated
  using (user_id = (select auth.uid()));


-- ============================================================================
-- 7) Supabase Storage — bucket خاص للأصول
--    البنية الإلزامية للمسار: user-assets/{user_id}/{filename}
--    الحماية: السياسات تمنع أي مستخدم من لمس مجلد غيره.
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'user-assets',
  'user-assets',
  false,
  5242880, -- 5MB
  array['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- قراءة/تعديل/حذف مقتصرة على المجلد المسمّى بمعرّف المستخدم نفسه
drop policy if exists "user_assets_storage_select_own" on storage.objects;
create policy "user_assets_storage_select_own"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'user-assets'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "user_assets_storage_insert_own" on storage.objects;
create policy "user_assets_storage_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'user-assets'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "user_assets_storage_update_own" on storage.objects;
create policy "user_assets_storage_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'user-assets'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'user-assets'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "user_assets_storage_delete_own" on storage.objects;
create policy "user_assets_storage_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'user-assets'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );


-- ============================================================================
-- 8) منح الصلاحيات (مطلوب لأن RLS تعمل فوق الـ GRANTS)
-- ============================================================================
grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on public.templates   to authenticated;
grant select, insert, update                on public.profiles    to authenticated;
grant select, insert, update, delete        on public.user_assets to authenticated;

-- anon ليس له أي وصول لجداول البيانات (لا قراءة قبل تسجيل الدخول)
revoke all on public.profiles    from anon;
revoke all on public.templates   from anon;
revoke all on public.user_assets from anon;


-- ============================================================================
-- 9) Backfill — إنشاء ملفات تعريف للمستخدمين الموجودين سابقاً (آمن الإعادة)
-- ============================================================================
insert into public.profiles (id, full_name)
select u.id,
       coalesce(u.raw_user_meta_data ->> 'full_name', split_part(coalesce(u.email, ''), '@', 1))
  from auth.users u
 where not exists (select 1 from public.profiles p where p.id = u.id);


-- ============================================================================
-- 10) تحقّق سريع (اختياري — يعرض نتيجة الاستعلام في SQL Editor)
-- ============================================================================
-- select tablename, rowsecurity from pg_tables
--   where schemaname = 'public' order by tablename;
-- select schemaname, tablename, policyname, cmd from pg_policies
--   where schemaname in ('public', 'storage') order by tablename, policyname;

-- ✅ نهاية التأسيس.
