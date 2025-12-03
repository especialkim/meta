#!/bin/bash

# ===========================================
# 프로젝트 템플릿 초기화 + Meta Server 실행
# 사용법: ./setup-and-run.sh [새로운-origin-url]
#
# 이 스크립트는 최초 1회만 실행됩니다.
# 실행 후 run.sh가 생성되며, 이후에는 run.sh로 서버를 실행하세요.
# ===========================================

set -e

echo "🚀 프로젝트 템플릿 초기화 시작..."

# 1. 기존 git history 제거
if [ -d ".git" ]; then
  echo "📦 기존 git history 제거..."
  rm -rf .git
fi

# 2. 새 git 저장소 초기화
echo "🔧 새 git 저장소 초기화..."
git init

# 3. 새 origin 설정 (인자로 받은 경우)
if [ -n "$1" ]; then
  echo "🔗 새 origin 설정: $1"
  git remote add origin "$1"
fi

# 4. _meta 내부 정리 (템플릿 파일들 유지, 실제 내용은 비움)
echo "🧹 _meta 폴더 정리..."

# devlog 정리 (__template__.md 제외)
find ./_meta/devlog -name "*.md" ! -name "__template__.md" -delete 2>/dev/null || true

# decisions, stages, specs 비우기
rm -f ./_meta/decisions/*.md 2>/dev/null || true
rm -f ./_meta/stages/*.md 2>/dev/null || true
rm -f ./_meta/specs/*.md 2>/dev/null || true

# inbox.md 메모 섹션 비우기
if [ -f "./_meta/inbox.md" ]; then
  sed -i '' '/^## 메모$/,$d' ./_meta/inbox.md 2>/dev/null || sed -i '/^## 메모$/,$d' ./_meta/inbox.md
  echo -e "\n## 메모\n" >> ./_meta/inbox.md
fi

# plan.md 초기화 (현재 상태만 리셋)
if [ -f "./_meta/plan.md" ]; then
  sed -i '' 's/Current: .*/Current: 미정/' ./_meta/plan.md 2>/dev/null || sed -i 's/Current: .*/Current: 미정/' ./_meta/plan.md
fi

# 5. meta server 의존성 설치
echo "📥 meta server 의존성 설치..."
cd ./_meta/server && npm install && cd ../..

# 6. meta-run.sh 생성
echo "📝 meta-run.sh 생성..."
cat > meta-run.sh << 'EOF'
#!/bin/bash

# ===========================================
# Meta Server 실행
# 사용법: ./meta-run.sh
# ===========================================

cd "$(dirname "$0")/_meta/server"
npm run watch
EOF
chmod +x meta-run.sh

# 7. 초기 커밋
echo "📝 초기 커밋 생성..."
git add .
git commit -m "Initial commit from template"

echo ""
echo "✅ 초기화 완료!"
echo ""

# 8. 이 스크립트 자체 삭제
echo "🗑️  setup-and-run.sh 삭제..."
SCRIPT_PATH="$(pwd)/setup-and-run.sh"

echo ""
echo "🚀 Meta Server 시작..."
echo "   (Ctrl+C로 종료)"
echo ""

# 스크립트 삭제 후 서버 실행 (백그라운드에서 삭제)
(sleep 1 && rm -f "$SCRIPT_PATH") &

# 서버 실행
cd ./_meta/server && npm run watch
