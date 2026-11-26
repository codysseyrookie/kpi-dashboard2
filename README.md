# KPI 대시보드

## 파일 역할

- `index.html`: 대시보드 구조와 상대 경로 파일 연결
- `style.css`: 기존 화면 스타일
- `dashboard.js`: 기존 필터, 요약·차트·근거표 렌더링
- `app.js`: 화면 상태, 샘플 입력, 로그인·저장 폼 조정
- `core.js`: 가상 샘플, 입력값 검사, 합계와 달성률 계산
- `backend.js`: 향후 Supabase 연결을 위한 데이터 경계 초안. 현재 단계에서는 실제 DB 연결을 수행하지 않음
- `vendor/supabase.js`: 로컬 Supabase JS SDK. `vendor/Supabase_LICENSE`와 `vendor/출처.md`를 함께 보존
- `data/kpi.json`, `data/kpi.csv`: UTF-8 샘플 사본. 가져오기·원본 비교용이며 현재 화면은 읽지 않음
- `prd.md`: 원본 화면에서 확인한 사실과 다음 단계 제안을 구분
- `schema.sql`: 빈 새 DB용 제안 스키마. 실제 DB에 실행하지 않음
- `schema.existing-db-migration.sql`: 기존 DB 읽기 전용 사전 확인과 수동 변경 후보. 실제 DB에 실행하지 않음
- `저장구조.md`: 저장 행의 의미, 필수값·범위·중복·RLS 및 금지 입력 설명
- `config.example.js`: 공개 URL·publishable key 설정 예시
- `config.js`: 기존 공개 설정 파일. 기존 파일은 보존하며 실제 값을 복사하거나 출력하지 않음
- `검증체크리스트.md`: 샘플 화면 확인과 향후 실제 DB 검증 항목

## 실행법

`index.html`을 브라우저에서 직접 열면 샘플 화면을 볼 수 있습니다. 권장 실행은 앱 폴더에서 로컬 HTTP 서버(예: `py -m http.server 8000`)를 실행해 `http://localhost:8000`으로 여는 방법입니다. 샘플 화면은 `core.js`의 가상 데이터를 사용하므로 JSON·CSV를 `fetch()`하지 않습니다.

다음 단계에서 Supabase를 연결할 때만 `config.example.js`를 참고해 공개 URL과 publishable key를 준비하고, `schema.sql`의 테이블·RLS 설계를 검토합니다. 이번 단계에서는 설정값을 읽어 연결하거나 로그인하지 않습니다.

## 샘플과 DB의 차이

- 샘플 모드는 가상 6건을 메모리에서 조회·계산하며 실제 DB에 저장하지 않습니다.
- 샘플 입력은 현재 화면의 메모리 데이터에만 한 건을 추가하며 새로고침하면 사라집니다.
- DB 연결 파일은 다음 단계 검토용이며, 현재 단계에서는 로그인·DB 조회·DB 저장을 수행하지 않습니다.
- JSON·CSV는 샘플 복사본이며 현재 앱에서 가져오거나 저장하지 않습니다.
- 실제 로그인·DB 접근은 현재 범위 밖입니다. `config.example.js`와 `config.js`는 공개 설정 자리표시자/보존용 파일이며, 실제 값을 복사하거나 출력하지 않습니다.
- SQL은 검토용 설계입니다. `schema.sql`은 새 DB를 가정한 연결 준비안이며 실제 실행하지 않습니다. 기존 DB에는 실행하지 말고 별도 migration 파일을 먼저 읽기 전용으로 검토해야 합니다.
- 실제 원격 DB가 프로젝트 안의 SQL 파일과 같은 구조인지 확인하지 못했습니다. migration 파일은 기본적으로 데이터 변경 없이 확인 쿼리만 실행하도록 두었고 변경 예시는 주석 처리되어 있습니다.

## GitHub에 올릴 파일

샘플 실행에는 `index.html`, `style.css`, `app.js`, `dashboard.js`, `core.js`가 필요합니다. JSON·CSV는 가져오기·원본 비교용 샘플 사본입니다. 연결 준비 파일을 함께 보관하려면 `backend.js`, `config.example.js`, `config.js`, `schema.sql`, `schema.existing-db-migration.sql`을 포함할 수 있습니다. `vendor/` 파일은 연결 검토 시에만 필요합니다. 비밀번호·secret/service_role key는 절대 포함하지 마세요.

화면에서 확인한 기능과 연결 구현 범위는 `prd.md`에 구분했습니다. 실제 로그인·새로고침 재조회·RLS를 확인하는 순서는 `검증체크리스트.md`를 참고하세요.
