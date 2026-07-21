-- ============================================================
-- 참여후기 공모전 BEST 3 투표 시스템 - DB 세팅
-- Supabase 대시보드 > SQL Editor 에 전체 붙여넣고 Run 한 번 실행
-- ============================================================

-- ⚠️ 작품 3개의 제목/작성자/소개는 아직 임시값 — 확정되면 update로 수정

-- 재실행 대비 초기화
drop function if exists contest_get_results(text);
drop function if exists contest_public_state();
drop function if exists contest_reset(text);
drop function if exists contest_recent_votes(text);
drop function if exists contest_set_open(text, boolean);
drop function if exists contest_is_open();
drop table if exists contest_votes;
drop table if exists contest_entries;
drop table if exists contest_settings;

-- 작품 목록
create table contest_entries (
  id int primary key,
  title text not null,
  author text,
  description text,
  image_url text,
  sort_order int not null default 0
);

-- 투표 기록 (기기당 1표: device_id 유니크 제약이 최후의 방어선)
create table contest_votes (
  id uuid primary key default gen_random_uuid(),
  entry_id int not null references contest_entries(id),
  device_id text not null unique,
  fingerprint text,
  created_at timestamptz not null default now()
);

-- 운영 설정 (투표 열림/마감 + 관리자 비밀번호)
create table contest_settings (
  id int primary key,
  is_open boolean not null default true,
  admin_pass text not null,
  round int not null default 1          -- 초기화할 때마다 +1, 이전 회차 투표 기기의 재투표 허용용
);

insert into contest_settings (id, is_open, admin_pass)
values (1, true, '1939');

-- 작품 3개
insert into contest_entries (id, title, author, description, image_url, sort_order) values
  (1, '드림청년 생존일지', '노나은', null, null, 1),
  (2, '신입은 경력을 어떻게 쌓나요?', '박시온', null, null, 2),
  (3, '경로를 재탐색합니다.', '허유진', null, null, 3);

-- ------------------------------------------------------------
-- 투표 진행 여부 함수 (RLS 정책과 참여 화면에서 공용)
-- security definer 라서 settings 테이블의 RLS를 우회해 읽을 수 있음
-- ------------------------------------------------------------
create or replace function contest_is_open()
returns boolean
language sql security definer stable
set search_path = public
as $$
  select is_open from contest_settings where id = 1;
$$;

-- ------------------------------------------------------------
-- 보안 (RLS): 참여자는 작품 읽기 + 투표 저장만 가능, 결과 조회 불가
-- ------------------------------------------------------------
alter table contest_entries enable row level security;
alter table contest_votes enable row level security;
alter table contest_settings enable row level security;

-- 작품 목록은 누구나 읽기 가능
create policy "entries_read" on contest_entries for select using (true);

-- 투표는 "열려있을 때"만 저장 가능, 읽기 정책 없음 → 참여자는 결과를 절대 못 봄
-- 주의: settings를 직접 select하면 RLS에 막혀 항상 거부되므로 반드시 함수 사용
create policy "votes_insert_when_open" on contest_votes for insert
  with check (contest_is_open());

-- settings 는 정책 없음 → 비밀번호가 노출될 일 없음

-- 참여자 화면용 공개 상태: 진행 여부 + 총 참여 수만 (작품별 득표는 비공개 유지)
create or replace function contest_public_state()
returns json
language sql security definer stable
set search_path = public
as $$
  select json_build_object(
    'is_open', (select is_open from contest_settings where id = 1),
    'total',   (select count(*) from contest_votes),
    'round',   (select round from contest_settings where id = 1)
  );
$$;

-- ------------------------------------------------------------
-- 진행자 전용 함수 (비밀번호 검증 후에만 동작)
-- ------------------------------------------------------------

-- 결과 집계
create or replace function contest_get_results(pass text)
returns table(entry_id int, title text, author text, vote_count bigint)
language plpgsql security definer
set search_path = public
as $$
begin
  if not exists (select 1 from contest_settings s where s.id = 1 and s.admin_pass = pass) then
    raise exception 'INVALID_PASS';
  end if;
  return query
    select e.id, e.title, e.author, count(v.id)::bigint
    from contest_entries e
    left join contest_votes v on v.entry_id = e.id
    group by e.id, e.title, e.author
    order by count(v.id) desc, e.id;
end;
$$;

-- 최근 투표 기록 (조작 의심 시 시간 패턴 확인용)
create or replace function contest_recent_votes(pass text)
returns table(voted_at timestamptz, entry_id int)
language plpgsql security definer
set search_path = public
as $$
begin
  if not exists (select 1 from contest_settings s where s.id = 1 and s.admin_pass = pass) then
    raise exception 'INVALID_PASS';
  end if;
  return query
    select v.created_at, v.entry_id
    from contest_votes v
    order by v.created_at desc
    limit 30;
end;
$$;

-- 투표 기록 초기화 (리허설 → 본행사 전환용): 표 전체 삭제 + 회차 증가 + 투표 열기
create or replace function contest_reset(pass text)
returns int
language plpgsql security definer
set search_path = public
as $$
begin
  if not exists (select 1 from contest_settings s where s.id = 1 and s.admin_pass = pass) then
    raise exception 'INVALID_PASS';
  end if;
  delete from contest_votes where true;  -- where 절 필수 정책(safeupdate) 대응
  update contest_settings set round = round + 1, is_open = true where id = 1;
  return (select round from contest_settings where id = 1);
end;
$$;

-- 투표 열기/마감
create or replace function contest_set_open(pass text, open_state boolean)
returns boolean
language plpgsql security definer
set search_path = public
as $$
begin
  if not exists (select 1 from contest_settings s where s.id = 1 and s.admin_pass = pass) then
    raise exception 'INVALID_PASS';
  end if;
  update contest_settings set is_open = open_state where id = 1;
  return open_state;
end;
$$;
