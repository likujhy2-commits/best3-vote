# 참여후기 공모전 BEST 3 투표 시스템

행사장에서 약 300명이 QR로 접속해 작품 3개 중 1개에 투표하는 시스템.
참여자는 결과를 볼 수 없고, 진행자만 비밀번호로 실시간 결과를 확인합니다.

## 구성

| 파일 | 용도 |
|---|---|
| `index.html` | 참여자 투표 화면 (소개 → 투표 → 완료) |
| `admin.html` | 진행자 전용 결과 대시보드 (비밀번호 필요) |
| `config.js` | Supabase 접속 정보 |
| `setup.sql` | DB 세팅 SQL (Supabase SQL Editor에서 1회 실행) |

## 준비 순서

1. **DB 세팅** — [Supabase 대시보드](https://supabase.com/dashboard/project/sqreqoewqfusppayoiqw) > SQL Editor 에서 `setup.sql` 내용 전체를 붙여넣고 Run.
   - 실행 전 파일 안의 ⚠️ 표시 두 곳 수정: **관리자 비밀번호**(`dream2026`)와 **작품 3개 정보**
2. **배포** — Vercel에 이 폴더를 배포 (또는 GitHub Pages). 정적 파일이라 빌드 설정 불필요.
3. **QR 생성** — 배포된 주소(`https://.../index.html`)로 QR코드를 만들어 행사 화면에 표시.
4. **진행자** — `https://.../admin.html` 접속 → 비밀번호 입력.

## 행사 당일 운영

1. 작품 소개 후 QR 공개 → 참여자 투표
2. 진행자는 `admin.html`에서 실시간 득표 확인 (3초 자동 갱신)
3. 투표 종료 시점에 **"투표 마감하기"** 클릭 → 이후 참여자는 투표 불가
4. 쉬는 시간에 결과 확인 → 사회자 발표

## 보안 / 중복 방지

- 기기당 1표: localStorage + 기기 ID 유니크 제약(DB 레벨)
- 참여자는 투표 데이터를 읽을 수 없음 (RLS로 INSERT만 허용)
- 관리자 비밀번호는 DB 안에만 있고, 검증은 서버(DB 함수)에서 수행
- 시크릿 모드로 재투표는 기술적으로 가능 — 의심되면 대시보드의 "최근 투표 기록"에서 시간 패턴 확인

## 작품 정보 수정

`setup.sql`을 다시 실행하면 투표 기록이 초기화되므로, **투표 시작 후에는 재실행 금지**.
작품 문구만 고치려면 SQL Editor에서:

```sql
update contest_entries set title = '새 제목', description = '새 소개' where id = 1;
```

투표 기록만 초기화(리허설 후 본행사 전):

```sql
delete from contest_votes;
```
