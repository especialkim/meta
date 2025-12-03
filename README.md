# _meta Template

AI와 함께 작업할 때 프로젝트 정보를 체계적으로 관리하는 템플릿입니다.

## 빠른 시작

### 방법 1: workspace 명령어 (권장)

한 번 설치하면 어디서든 `workspace` 명령어로 사용할 수 있습니다.

**설치:** (프로젝트 루트에서 실행)
```bash
# ~/bin 폴더 생성 (없으면)
mkdir -p ~/bin

# 스크립트 복사
cp _meta/server/workspace.sh ~/bin/workspace
chmod +x ~/bin/workspace

# PATH에 추가 (최초 1회만, ~/.zshrc 또는 ~/.bashrc)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**사용:**
```bash
# 새 프로젝트 만들기
workspace my-project

# 새 프로젝트 + GitHub 연결까지
workspace my-project https://github.com/user/my-project.git

# 이미 있는 프로젝트에 _meta 추가하기
cd existing-project
workspace
```

### 방법 2: clone해서 쓰기

```bash
# 1. 템플릿 clone
git clone https://github.com/especialkim/meta.git my-project
cd my-project

# 2-A. 새 프로젝트로 시작
./setup-and-run.sh

# 2-B. 새 프로젝트 + GitHub 연결
./setup-and-run.sh https://github.com/user/my-project.git

# 2-C. 기존 프로젝트 안에 clone했다면 (부모 폴더에 _meta 추가)
./setup-and-run.sh --add-to-existing
```

### 서버 실행

초기화가 끝나면 `meta-run.sh`가 생성됩니다. 이걸로 인덱스 서버를 실행하세요.

```bash
./meta-run.sh
```

## 폴더 구조

```
프로젝트/
├── CLAUDE.md              # Claude용 진입점
├── AGENT.md               # Cursor Agent용 진입점
├── GEMINI.md              # Gemini용 진입점
├── _meta/
│   ├── GUIDE.md           # 작업 규칙 (AI가 참고)
│   ├── plan.md            # 프로젝트 계획, 로드맵
│   ├── inbox.md           # 아이디어, 메모 임시 저장소
│   ├── specs/             # 확정된 스펙 문서
│   ├── decisions/         # 결정 기록
│   ├── stages/            # 단계별 상세 계획
│   ├── devlog/            # 개발 일지
│   └── server/            # 인덱스 자동 생성 서버
├── setup-and-run.sh       # 초기화용 (1회만 실행)
└── meta-run.sh            # 서버 실행용 (초기화 후 생성)
```

## AI에게 말하는 키워드

| 이렇게 말하면 | AI가 하는 일 |
|--------------|-------------|
| "수신함 검토해줘" | inbox 내용을 적절한 문서에 정리 |
| "정리하자" / "기록해" | devlog에 작업 내용 기록 |
| "결정사항으로 남겨" | decisions/에 결정 내용 저장 |
| "플랜 업데이트" | plan.md 수정 |
| "지금 어디야?" | 현재 진행 상황 확인 |
| "어디까지 했지?" | 최근 작업 내용 요약 |

## Meta Server

`./meta-run.sh`를 실행하면 파일 변경을 감지해서 인덱스를 자동으로 업데이트합니다.

직접 실행하고 싶다면:
```bash
cd _meta/server
npm run watch   # 파일 변경 감지 모드
npm start       # 한 번만 실행
```
