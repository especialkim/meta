# _meta Template

AI 협업을 위한 프로젝트 메타 정보 관리 템플릿.

## 사용법

### 방법 1: workspace 명령어 (권장)

글로벌 명령어로 등록하면 어디서든 사용 가능.

**설치:**
```bash
# 스크립트 복사
cp _meta/server/workspace.sh ~/bin/workspace
chmod +x ~/bin/workspace

# PATH 추가 (~/.zshrc 또는 ~/.bashrc)
export PATH="$HOME/bin:$PATH"
```

**사용:**
```bash
# 새 프로젝트 생성
workspace my-project

# 새 프로젝트 + origin 설정
workspace my-project https://github.com/user/my-project.git

# 기존 프로젝트에 _meta 추가
cd existing-project
workspace
```

### 방법 2: 수동 clone + setup

```bash
git clone https://github.com/especialkim/meta.git my-project
cd my-project
./setup-and-run.sh https://github.com/YOUR_USERNAME/my-project.git
```

### 이후 실행

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
