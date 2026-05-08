#!/usr/bin/env bash
# DFA 后置校验门 - 对 AI 生成代码执行项目级类型检查和目标文件级 lint。
# 用法: ./scripts/lint-check.sh [目标路径，默认 .]
set -euo pipefail

TARGET=${1:-.}
ERRORS=0
WARNINGS=0
MAX_COMPONENT_LINES=${MAX_COMPONENT_LINES:-300}
DFA_PROJECT_TSC=${DFA_PROJECT_TSC:-auto}
TARGET_IS_FILE=0
TS_LIKE_FILES=()
PYTHON_FILES=()
SIZE_CHECK_FILES=()

report_error() {
  echo "❌ $1"
  ERRORS=$((ERRORS + 1))
}

report_warning() {
  echo "⚠️  $1"
  WARNINGS=$((WARNINGS + 1))
}

report_info() {
  echo "ℹ️  $1"
}

add_target_file() {
  local file_path=$1

  case "$file_path" in
    *.ts | *.tsx | *.vue)
      TS_LIKE_FILES+=("$file_path")
      SIZE_CHECK_FILES+=("$file_path")
      ;;
    *.py)
      PYTHON_FILES+=("$file_path")
      SIZE_CHECK_FILES+=("$file_path")
      ;;
  esac
}

collect_target_files() {
  if [ ! -e "$TARGET" ]; then
    report_error "目标路径不存在：$TARGET"
    return
  fi

  if [ -f "$TARGET" ]; then
    TARGET_IS_FILE=1
    add_target_file "$TARGET"
    return
  fi

  while IFS= read -r -d '' file_path; do
    add_target_file "$file_path"
  done < <(
    find "$TARGET" \
      \( -type d \( \
        -name .git -o \
        -name node_modules -o \
        -name dist -o \
        -name build -o \
        -name coverage -o \
        -name .next -o \
        -name .nuxt -o \
        -name .venv -o \
        -name venv -o \
        -name __pycache__ \
      \) -prune \) -o \
      -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.vue" -o -name "*.py" \) \
      -print0
  )
}

run_project_tsc() {
  case "$DFA_PROJECT_TSC" in
    0 | false | no | off)
      report_info "DFA_PROJECT_TSC=$DFA_PROJECT_TSC，跳过项目级 TSC。"
      return 0
      ;;
    1 | true | yes | on)
      ;;
    auto)
      if [ "$TARGET_IS_FILE" -eq 1 ]; then
        report_info "单文件目标默认跳过项目级 TSC；如需项目类型检查请设置 DFA_PROJECT_TSC=1。"
        return 0
      fi
      ;;
    *)
      report_warning "未知 DFA_PROJECT_TSC=$DFA_PROJECT_TSC，按 auto 处理。"
      if [ "$TARGET_IS_FILE" -eq 1 ]; then
        return 0
      fi
      ;;
  esac

  if [ ! -f "tsconfig.json" ]; then
    report_warning "未找到 tsconfig.json，跳过 TSC；请在目标项目根目录运行。"
    return 0
  fi

  if npx --no-install tsc --noEmit --strict; then
    echo "✅ TSC 通过"
  else
    report_error "TSC 发现类型错误"
  fi
}

run_eslint() {
  if npx --no-install eslint \
    --rule '{"@typescript-eslint/no-explicit-any": "error"}' \
    --rule '{"no-magic-numbers": ["warn", {"ignore": [0, 1, -1]}]}' \
    --rule '{"max-params": ["warn", {"max": 2}]}' \
    --max-warnings 0 \
    --format stylish \
    -- \
    "${TS_LIKE_FILES[@]}"; then
    echo "✅ ESLint 通过"
  else
    report_error "ESLint 发现错误或警告"
  fi
}

run_ruff() {
  if command -v ruff >/dev/null 2>&1; then
    ruff check "${PYTHON_FILES[@]}"
  elif command -v python3 >/dev/null 2>&1 && python3 -m ruff --version >/dev/null 2>&1; then
    python3 -m ruff check "${PYTHON_FILES[@]}"
  else
    return 127
  fi
}

run_mypy() {
  if command -v mypy >/dev/null 2>&1; then
    mypy --strict "${PYTHON_FILES[@]}"
  elif command -v python3 >/dev/null 2>&1 && python3 -m mypy --version >/dev/null 2>&1; then
    python3 -m mypy --strict "${PYTHON_FILES[@]}"
  else
    return 127
  fi
}

collect_target_files

echo "━━━ [1/4] TypeScript 类型检查 ━━━"
if [ "${#TS_LIKE_FILES[@]}" -eq 0 ]; then
  echo "✅ 未发现 TypeScript/Vue 目标文件"
elif ! command -v npx >/dev/null 2>&1; then
  report_error "未找到 npx，无法运行 TSC/ESLint。"
else
  run_project_tsc
fi

echo ""
echo "━━━ [2/4] ESLint 规则检查 ━━━"
if [ "${#TS_LIKE_FILES[@]}" -eq 0 ]; then
  echo "✅ 未发现需要 ESLint 检查的目标文件"
elif ! command -v npx >/dev/null 2>&1; then
  report_error "未找到 npx，无法运行 ESLint。"
else
  run_eslint
fi

echo ""
echo "━━━ [3/4] Python 质量检查 ━━━"
if [ "${#PYTHON_FILES[@]}" -eq 0 ]; then
  echo "✅ 未发现 Python 目标文件"
else
  if run_ruff; then
    echo "✅ Ruff 通过"
  elif [ "$?" -eq 127 ]; then
    report_warning "未找到 ruff，跳过 Python lint。"
  else
    report_error "Ruff 发现问题"
  fi

  if run_mypy; then
    echo "✅ Mypy 通过"
  elif [ "$?" -eq 127 ]; then
    report_warning "未找到 mypy，跳过 Python 类型检查。"
  else
    report_error "Mypy 发现类型问题"
  fi
fi

echo ""
echo "━━━ [4/4] 文件行数检查 ━━━"
if [ "${#SIZE_CHECK_FILES[@]}" -eq 0 ]; then
  echo "✅ 未发现需要行数检查的目标文件"
else
  for file_path in "${SIZE_CHECK_FILES[@]}"; do
    line_count=$(wc -l < "$file_path" | tr -d ' ')
    if [ "$line_count" -gt "$MAX_COMPONENT_LINES" ]; then
      report_warning "$file_path 超过 ${MAX_COMPONENT_LINES} 行（${line_count} 行）→ 建议拆分职责"
    fi
  done
  echo "✅ 行数检查完成"
fi

echo ""
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "🎉 基础静态门禁通过"
  exit 0
fi

echo "⚠️  发现 ${ERRORS} 处错误、${WARNINGS} 处警告，请参照 DFA 规则修正后重新生成"
exit 1
