-- KPI DB 연결 준비용 설계안
-- 실제 데이터베이스에 실행하지 마세요.
-- 기존 테이블에 덮어쓰거나 재생성하지 마세요.
-- 원본 화면에서 확인한 업무 필드는 month, team, target, actual입니다.
-- id, user_id, created_at, 제약, RLS는 DB 연결을 위한 추가 설계입니다.

begin;

create table public.kpi_records (
  -- 추가 설계: DB 행 식별자
  id uuid primary key default gen_random_uuid(),
  -- 추가 설계: 인증 사용자 소유자
  user_id uuid not null references auth.users (id),

  -- 원본 화면에서 확인한 업무 항목
  month text not null,
  team text not null,
  target bigint not null,
  actual bigint not null,

  -- 추가 설계: 생성 시각
  created_at timestamptz not null default now(),

  -- 추가 설계: YYYY-MM 형식
  constraint kpi_records_month_format
    check (month ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  -- 추가 설계: 부서명은 앞뒤 공백을 제외하고 1~80자
  constraint kpi_records_team_length
    check (team = btrim(team) and char_length(team) between 1 and 80),
  -- 추가 설계: 원 단위의 0 이상 안전한 정수
  constraint kpi_records_target_safe_integer
    check (target between 0 and 9007199254740991),
  constraint kpi_records_actual_safe_integer
    check (actual between 0 and 9007199254740991),
  -- 추가 설계: 한 사용자의 한 달·한 부서에 한 행
  constraint kpi_records_user_month_team_unique
    unique (user_id, month, team)
);

comment on table public.kpi_records is
  'Proposed KPI table. Do not run this design without reviewing the target database.';
comment on column public.kpi_records.month is
  'Confirmed from original screen: YYYY-MM month';
comment on column public.kpi_records.team is
  'Confirmed from original screen: department';
comment on column public.kpi_records.target is
  'Confirmed from original screen: target amount in KRW';
comment on column public.kpi_records.actual is
  'Confirmed from original screen: actual amount in KRW';
comment on column public.kpi_records.id is
  'Additional DB design: generated row UUID';
comment on column public.kpi_records.user_id is
  'Additional DB design: authenticated owner';
comment on column public.kpi_records.created_at is
  'Additional DB design: creation timestamp';

-- 추가 설계: 인증 사용자만 접근하고, 본인 행만 허용
alter table public.kpi_records enable row level security;
revoke all on table public.kpi_records from public, anon;
grant select, insert, update, delete on table public.kpi_records to authenticated;

create policy kpi_records_select_own
  on public.kpi_records for select to authenticated
  using ((select auth.uid()) = user_id);

create policy kpi_records_insert_own
  on public.kpi_records for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy kpi_records_update_own
  on public.kpi_records for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy kpi_records_delete_own
  on public.kpi_records for delete to authenticated
  using ((select auth.uid()) = user_id);

commit;
