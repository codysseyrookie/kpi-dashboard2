-- EXISTING DATABASE REVIEW TEMPLATE. Not executed.
-- Do not paste/run the whole file blindly. Run the read-only inventory first.
-- The project has multiple historical schema.sql versions; remote DB state is unknown.
-- No statements in the review section delete or update existing rows.

-- 1) Confirm whether the expected table exists.
select to_regclass('public.kpi_records') as table_found;

-- 2) If the table exists, inspect actual column names, types, nullability, and defaults.
select column_name, data_type, udt_name, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'kpi_records'
order by ordinal_position;

-- 3) Inspect constraints, including their expressions and key columns.
select conname, contype, convalidated, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = to_regclass('public.kpi_records')
order by conname;

-- 4) Inspect all policies. Permissive policies can combine with OR, so a broad
-- existing policy can defeat a new owner-only policy. Review before adding policies.
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'kpi_records'
order by policyname;

-- 5) Inspect RLS state and table grants.
select c.relrowsecurity as rls_enabled, c.relforcerowsecurity as rls_forced
from pg_class c where c.oid = to_regclass('public.kpi_records');
select grantee, privilege_type
from information_schema.role_table_grants
where table_schema = 'public' and table_name = 'kpi_records'
order by grantee, privilege_type;

-- 6) Only after confirming the table and columns above, run these read-only data checks.
-- Do not delete duplicates or silently rewrite invalid values. Decide a reviewed
-- row-by-row repair/backfill plan first; preserve original values for audit.
-- Skip a query if any referenced column is absent; a missing required column is a
-- stop condition, not permission to guess or silently backfill it.
select count(*) as null_required_fields
from public.kpi_records
where id is null or user_id is null or month is null or team is null
   or target is null or actual is null or created_at is null;

select count(*) as invalid_month_rows
from public.kpi_records
where month !~ '^[0-9]{4}-(0[1-9]|1[0-2])$';

select count(*) as invalid_team_rows
from public.kpi_records
where team <> btrim(team) or char_length(btrim(team)) not between 1 and 80;

select count(*) as invalid_amount_rows
from public.kpi_records
where target < 0 or target > 9007199254740991
   or actual < 0 or actual > 9007199254740991;

select user_id, month, team, count(*) as duplicate_count
from public.kpi_records
group by user_id, month, team
having count(*) > 1;

select user_id, source_id, count(*) as duplicate_count
-- Run this query only when information_schema confirms source_id exists.
from public.kpi_records
where source_id is not null
group by user_id, source_id
having count(*) > 1;

select k.id, k.user_id
from public.kpi_records k
left join auth.users u on u.id = k.user_id
where k.user_id is not null and u.id is null;

-- 7) Candidate additive changes (review and run individually only after all checks).
-- These are intentionally comments so the file's default execution is read-only.
-- First confirm every referenced column already exists with the expected type.
-- If a required column is missing, stop: user ownership/history cannot be inferred.
--
-- begin;
-- alter table public.kpi_records add column source_id text;
--   -- Only if source_id is absent. Existing NULLs are retained; no backfill is guessed.
-- alter table public.kpi_records alter column user_id set default auth.uid();
-- alter table public.kpi_records alter column created_at set default now();
--   -- Defaults affect future inserts only; existing timestamps are not rewritten.
-- alter table public.kpi_records alter column id set not null;
-- alter table public.kpi_records alter column user_id set not null;
-- alter table public.kpi_records alter column month set not null;
-- alter table public.kpi_records alter column team set not null;
-- alter table public.kpi_records alter column target set not null;
-- alter table public.kpi_records alter column actual set not null;
-- alter table public.kpi_records alter column created_at set not null;
--   -- Run only after null checks return zero and types/defaults have been reviewed.
-- alter table public.kpi_records add constraint kpi_records_month_format
--   check (month ~ '^[0-9]{4}-(0[1-9]|1[0-2])$') not valid;
-- alter table public.kpi_records add constraint kpi_records_team_normalized_length
--   check (team = btrim(team) and char_length(team) between 1 and 80) not valid;
-- alter table public.kpi_records add constraint kpi_records_target_safe_integer
--   check (target between 0 and 9007199254740991) not valid;
-- alter table public.kpi_records add constraint kpi_records_actual_safe_integer
--   check (actual between 0 and 9007199254740991) not valid;
--   -- Validate each only after the corresponding invalid-row count is zero.
-- alter table public.kpi_records validate constraint kpi_records_month_format;
-- alter table public.kpi_records validate constraint kpi_records_team_normalized_length;
-- alter table public.kpi_records validate constraint kpi_records_target_safe_integer;
-- alter table public.kpi_records validate constraint kpi_records_actual_safe_integer;
-- create unique index kpi_records_user_month_team_uidx
--   on public.kpi_records (user_id, month, team);
-- create unique index kpi_records_user_source_uidx
--   on public.kpi_records (user_id, source_id);
--   -- Create only if equivalent uniqueness is absent and duplicate checks return no rows.
--   -- PostgreSQL permits multiple NULL source_id values in a normal UNIQUE index.
-- alter table public.kpi_records enable row level security;
-- revoke all on table public.kpi_records from public, anon;
-- grant select, insert, update, delete on table public.kpi_records to authenticated;
-- Add owner-only SELECT/INSERT/UPDATE/DELETE policies from schema.sql only after
-- reviewing every existing policy. Existing permissive policies can combine with OR.
-- commit;
--
-- Add/validate CHECK and NOT NULL constraints only after invalid/null counts are zero
-- or a reviewed non-destructive backfill has been completed. Do not guess owners or
-- historical created_at values. Inspect policies first; do not add owner-only policies
-- until any broad existing policy has been reviewed.
