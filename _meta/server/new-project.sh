#!/bin/bash

# ===========================================
# 글로벌 프로젝트 생성 스크립트
#
# 설치:
#   1. 이 파일을 ~/bin/new-project 로 복사
#   2. chmod +x ~/bin/new-project
#   3. ~/.zshrc 또는 ~/.bashrc 에 export PATH="$HOME/bin:$PATH" 추가
#
# 사용법:
#   new-project 프로젝트명 [새로운-origin-url]
#   new-project my-app https://github.com/user/my-app.git
# ===========================================

set -e

# 템플릿 저장소 URL (본인 저장소로 변경)
TEMPLATE_REPO="https://github.com/YOUR_USERNAME/YOUR_TEMPLATE_REPO.git"

# 인자 확인
if [ -z "$1" ]; then
  echo "사용법: new-project <프로젝트명> [origin-url]"
  echo "예시: new-project my-app https://github.com/user/my-app.git"
  exit 1
fi

PROJECT_NAME="$1"
NEW_ORIGIN="$2"

echo "🚀 새 프로젝트 생성: $PROJECT_NAME"

# 1. 템플릿 clone
echo "📦 템플릿 clone..."
git clone "$TEMPLATE_REPO" "$PROJECT_NAME"
cd "$PROJECT_NAME"

# 2. setup.sh 실행 (origin 인자 전달)
if [ -f "setup.sh" ]; then
  echo "🔧 초기화 스크립트 실행..."
  if [ -n "$NEW_ORIGIN" ]; then
    ./setup.sh "$NEW_ORIGIN"
  else
    ./setup.sh
  fi
else
  echo "⚠️  setup.sh 없음, 수동 초기화 필요"
fi

echo ""
echo "✅ 프로젝트 생성 완료!"
echo "📂 cd $PROJECT_NAME"
