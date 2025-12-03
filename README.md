# _meta Template

AI 협업을 위한 프로젝트 메타 정보 관리 템플릿.

## 사용법

### 1. 템플릿 clone

```bash
git clone https://github.com/YOUR_USERNAME/_meta-template.git my-project
cd my-project
```

### 2. 초기화 및 실행

```bash
./setup-and-run.sh https://github.com/YOUR_USERNAME/my-project.git
```

이 스크립트는:
- 템플릿 git history 제거 후 새로 초기화
- `_meta/` 내용 정리
- 의존성 설치
- `meta-run.sh` 생성
- 자기 자신 삭제
- Meta Server 실행

### 3. 이후 실행

```bash
./meta-run.sh
```

## 구조

```
/
├── CLAUDE.md              # AI 진입점 (트리거 + 자동 생성 인덱스)
├── _meta/
│   ├── GUIDE.md           # 작업 규칙 상세
│   ├── plan.md            # 프로젝트 방향, 로드맵
│   ├── inbox.md           # 아이디어/메모 수신함
│   ├── specs/             # 확정된 규칙/스펙
│   ├── decisions/         # 결정 히스토리
│   ├── stages/            # stage별 세부 계획
│   ├── devlog/            # 일일 개발 로그
│   └── server/            # Meta Server (인덱스 자동 생성)
├── setup-and-run.sh       # 초기화 스크립트 (1회용)
└── meta-run.sh            # 서버 실행 (setup 후 생성됨)
```

## 트리거 키워드

| 키워드 | 작업 |
|--------|------|
| "수신함 검토해줘" | inbox → 적절한 문서에 반영 |
| "정리하자" / "기록해" | devlog 작성 |
| "결정사항으로 남겨" | decisions/ 기록 |
| "플랜 업데이트" | plan.md 수정 |
| "지금 어디야?" | 현재 stage 확인 |
| "어디까지 했지?" | devlog + plan + stage 확인 |

## Meta Server

인덱스 자동 업데이트 서버. `./meta-run.sh`로 실행하면 됨.

수동 실행이 필요한 경우:
```bash
cd _meta/server
npm run watch   # 감시 모드
npm start       # 1회 실행
```
