#!/bin/bash

# ===========================================
# 프로젝트 템플릿 초기화 (clone 후 실행)
#
# 사용법:
#   ./setup-and-run.sh                    # 새 프로젝트로 초기화
#   ./setup-and-run.sh <origin-url>       # 새 프로젝트 + origin 설정
#   ./setup-and-run.sh --add-to-existing  # 기존 프로젝트에 _meta 추가
#
# 이 스크립트는 최초 1회만 실행됩니다.
# 실행 후 meta-run.sh가 생성되며, 이후에는 meta-run.sh로 서버를 실행하세요.
# ===========================================

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 헬퍼 함수
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 사용법 출력
usage() {
  echo "사용법:"
  echo "  ./setup-and-run.sh                    # 새 프로젝트로 초기화"
  echo "  ./setup-and-run.sh <origin-url>       # 새 프로젝트 + origin 설정"
  echo "  ./setup-and-run.sh --add-to-existing  # 기존 프로젝트에 _meta 추가"
  exit 0
}

# 공통 setup 함수 (npm install + meta-run.sh 생성 + pre-push 훅 설정)
do_setup() {
  # npm install
  info "meta server 의존성 설치..."
  cd _meta/server && npm install && cd ../..

  # meta-run.sh 생성
  info "meta-run.sh 생성..."
  cat > meta-run.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/_meta/server"
npm run watch
EOF
  chmod +x meta-run.sh

  # pre-push 훅 설정
  setup_pre_push_hook
}

# pre-push 훅 설정 함수
setup_pre_push_hook() {
  local hook_file=".git/hooks/pre-push"
  
  # .git 폴더가 있는지 확인
  if [ ! -d ".git" ]; then
    warn ".git 폴더가 없어서 pre-push 훅을 설정할 수 없습니다."
    return
  fi
  
  # hooks 폴더 생성 (없으면)
  mkdir -p .git/hooks
  
  info "pre-push 훅 설정..."
  
  cat > "$hook_file" << 'HOOK_EOF'
#!/bin/bash
# AI instruction 파일들을 자동으로 필터링하여 push
# 로컬에서는 AI 파일이 유지되지만, 원격에는 push되지 않습니다.
# git worktree를 사용하여 현재 작업 디렉토리를 건드리지 않습니다.

PROTECTED_FILES=("CLAUDE.md" "GEMINI.md" "AGENT.md" "_meta")
REMOTE="$1"

while read local_ref local_sha remote_ref remote_sha; do
  # 삭제되는 브랜치는 무시
  if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
    continue
  fi
  
  # 현재 브랜치 이름
  branch_name=$(echo "$local_ref" | sed 's|refs/heads/||')
  
  # AI 파일이 커밋에 있는지 확인
  has_protected=false
  for file in "${PROTECTED_FILES[@]}"; do
    if git ls-tree -r "$local_sha" --name-only 2>/dev/null | grep -q "^$file$"; then
      has_protected=true
      break
    fi
  done
  
  if [ "$has_protected" = true ]; then
    echo ""
    echo "🔄 AI 파일을 필터링하여 push 중..."
    
    # 임시 디렉토리 생성
    temp_dir=$(mktemp -d)
    temp_branch="__meta_temp_push_$$"
    
    # worktree 추가 (현재 디렉토리 영향 없음)
    git worktree add -q -b "$temp_branch" "$temp_dir" "$local_sha" 2>/dev/null
    
    if [ $? -ne 0 ]; then
      echo "❌ 임시 작업 공간 생성 실패"
      rm -rf "$temp_dir"
      exit 1
    fi
    
    # 임시 디렉토리에서 AI 파일 제거
    cd "$temp_dir"
    
    for file in "${PROTECTED_FILES[@]}"; do
      if git ls-files --error-unmatch "$file" 2>/dev/null; then
        git rm -q --cached "$file" 2>/dev/null
      fi
    done
    
    # 변경사항이 있으면 커밋 수정
    if ! git diff --cached --quiet; then
      git commit -q --amend --no-edit
    fi
    
    # 필터링된 커밋을 원격에 push
    git push --no-verify "$REMOTE" "HEAD:$branch_name" 2>&1
    push_result=$?
    
    # 원래 디렉토리로 복귀
    cd - > /dev/null
    
    # worktree 정리
    git worktree remove -f "$temp_dir" 2>/dev/null
    git branch -q -D "$temp_branch" 2>/dev/null
    rm -rf "$temp_dir" 2>/dev/null
    
    if [ $push_result -eq 0 ]; then
      echo "✅ Push 완료 (AI 파일 제외됨)"
      echo "   로컬의 AI 파일은 그대로 유지됩니다."
      echo ""
    else
      echo "❌ Push 실패"
      echo ""
    fi
    
    exit $push_result
  fi
done

exit 0
HOOK_EOF

  chmod +x "$hook_file"
  info "pre-push 훅 설정 완료"
}


# 스크립트 자체 삭제
cleanup_script() {
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/setup-and-run.sh"
  if [ -f "$SCRIPT_PATH" ]; then
    rm -f "$SCRIPT_PATH"
    info "setup-and-run.sh 삭제됨"
  fi
}

# 새 프로젝트 모드 (템플릿 clone 후 초기화)
new_project_mode() {
  local origin_url="$1"

  info "새 프로젝트로 초기화..."

  # 1. 기존 git history 제거 + 새로 초기화
  if [ -d ".git" ]; then
    rm -rf .git
  fi
  git init

  # 2. origin 설정 (있으면)
  if [ -n "$origin_url" ]; then
    git remote add origin "$origin_url"
    info "origin 설정: $origin_url"
  fi

  # 3. _meta 내용 정리
  info "_meta 폴더 정리..."
  find ./_meta/devlog -name "*.md" ! -name "__template__.md" -delete 2>/dev/null || true
  rm -f ./_meta/decisions/*.md 2>/dev/null || true
  rm -f ./_meta/stages/*.md 2>/dev/null || true
  rm -f ./_meta/specs/*.md 2>/dev/null || true

  # .gitkeep 유지 확인
  touch ./_meta/decisions/.gitkeep 2>/dev/null || true
  touch ./_meta/stages/.gitkeep 2>/dev/null || true
  touch ./_meta/specs/.gitkeep 2>/dev/null || true

  # inbox.md 메모 섹션 비우기
  if [ -f "./_meta/inbox.md" ]; then
    sed -i '' '/^## 메모$/,$d' ./_meta/inbox.md 2>/dev/null || sed -i '/^## 메모$/,$d' ./_meta/inbox.md
    echo -e "\n## 메모\n" >> ./_meta/inbox.md
  fi

  # plan.md 초기화
  if [ -f "./_meta/plan.md" ]; then
    sed -i '' 's/Current: .*/Current: 미정/' ./_meta/plan.md 2>/dev/null || sed -i 's/Current: .*/Current: 미정/' ./_meta/plan.md
  fi

  # 4. 공통 setup
  do_setup

  # 5. 스크립트 삭제
  cleanup_script

  # 6. 초기 커밋
  git add .
  git commit -m "Initial commit from _meta template"

  echo ""
  echo -e "${GREEN}✅ 완료!${NC}"
  echo ""
  echo "다음 단계:"
  echo "  1. _meta/plan.md 에 프로젝트 개요 작성"
  echo "  2. ./meta-run.sh 로 인덱스 서버 실행"
  if [ -z "$origin_url" ]; then
    echo "  3. git remote add origin <your-repo-url> 로 원격 저장소 연결"
  fi
}

# 기존 프로젝트에 _meta 추가 모드
add_meta_mode() {
  info "기존 프로젝트에 _meta 추가 모드"

  # 현재 위치가 clone된 템플릿 폴더라고 가정
  # 부모 폴더가 실제 프로젝트

  local template_dir="$(pwd)"
  local parent_dir="$(dirname "$template_dir")"

  # 1. 부모 폴더 확인
  if [ ! -d "$parent_dir/.git" ]; then
    warn "부모 폴더에 git 저장소가 없습니다: $parent_dir"
    read -p "그래도 계속하시겠습니까? (y/n): " choice
    if [ "$choice" != "y" ]; then
      error "취소됨"
    fi
  fi

  # 2. 부모 폴더에 이미 _meta/ 있는지 확인
  if [ -d "$parent_dir/_meta" ]; then
    warn "부모 폴더에 _meta/가 이미 존재합니다"
    read -p "덮어쓰시겠습니까? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
      error "취소됨"
    fi
    rm -rf "$parent_dir/_meta"
  fi

  # 3. 백업 폴더 생성 (충돌 파일 확인)
  local backup_dir="$parent_dir/_backup_$(date +%Y%m%d_%H%M%S)"
  local needs_backup=false

  for file in CLAUDE.md AGENT.md GEMINI.md; do
    if [ -f "$parent_dir/$file" ]; then
      needs_backup=true
      break
    fi
  done

  if [ "$needs_backup" = true ]; then
    info "기존 AI 설정 파일 백업 중..."
    mkdir -p "$backup_dir"
    for file in CLAUDE.md AGENT.md GEMINI.md; do
      if [ -f "$parent_dir/$file" ]; then
        mv "$parent_dir/$file" "$backup_dir/"
        info "  $file → $backup_dir/$file"
      fi
    done
  fi

  # 4. 필요한 파일들 복사
  info "템플릿 파일 복사 중..."

  # _meta/ 복사
  cp -r "$template_dir/_meta" "$parent_dir/"

  # AI 설정 파일들 복사
  cp "$template_dir/CLAUDE.md" "$parent_dir/"
  cp "$template_dir/AGENT.md" "$parent_dir/"
  cp "$template_dir/GEMINI.md" "$parent_dir/"

  # .gitignore 병합
  if [ -f "$parent_dir/.gitignore" ]; then
    info ".gitignore 병합 중..."
    echo "" >> "$parent_dir/.gitignore"
    echo "# === _meta template ===" >> "$parent_dir/.gitignore"
    cat "$template_dir/.gitignore" >> "$parent_dir/.gitignore"
    sort -u "$parent_dir/.gitignore" -o "$parent_dir/.gitignore"
  else
    cp "$template_dir/.gitignore" "$parent_dir/"
  fi

  # 5. 부모 폴더로 이동
  cd "$parent_dir"

  # 6. 공통 setup
  do_setup

  # 7. 템플릿 폴더 삭제
  info "템플릿 폴더 삭제..."
  rm -rf "$template_dir"

  # 8. 커밋
  info "변경사항 커밋..."
  git add .
  git commit -m "Add _meta workspace for AI collaboration"

  echo ""
  echo -e "${GREEN}✅ 완료!${NC}"
  echo ""
  echo "다음 단계:"
  echo "  1. _meta/plan.md 에 프로젝트 개요 작성"
  echo "  2. ./meta-run.sh 로 인덱스 서버 실행"
  if [ "$needs_backup" = true ]; then
    echo "  3. $backup_dir/ 에서 기존 파일 확인"
  fi
}

# 메인 로직
main() {
  # 인자 파싱
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
  fi

  # 케이스 분기
  if [ "$1" = "--add-to-existing" ]; then
    # 기존 프로젝트에 추가 모드
    add_meta_mode
  elif [ -n "$1" ]; then
    # origin URL이 주어진 경우 = 새 프로젝트 + origin
    new_project_mode "$1"
  else
    # 인자 없음 = 새 프로젝트로 초기화
    new_project_mode ""
  fi
}

main "$@"
