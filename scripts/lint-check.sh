#!/usr/bin/env bash
# DFA 后置校验门 - 对 AI 生成代码执行 TypeScript、ESLint 和行数检查。
# 用法: ./scripts/lint-check.sh [目标路径，默认 .]
set -euo pipefail

TARGET=${1:-.}
ERRORS=0
WARNINGS=0
MAX_COMPONENT_LINES=${MAX_COMPONENT_LINES:-300}

report_error() {
  echo "❌ $1"
  ERRORS=$((ERRORS + 1))
}

report_warning() {
  echo "⚠️  $1"
  WARNINGS=$((WARNINGS + 1))
}

has_matching_files() {
  find "$TARGET" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.vue" \) -print -quit | grep -q .
}

echo "━━━ [1/3] TypeScript 类型检查 ━━━"
if ! command -v npx >/dev/null 2>&1; then
  report_error "未找到 npx，请先安装 Node.js/npm。"
elif [ -f "tsconfig.json" ]; then
  if npx --yes tsc --noEmit --strict; then
    echo "✅ TSC 通过"
  else
    report_error "TSC 发现类型错误"
  fi
elif has_matching_files; then
  report_warning "未找到 tsconfig.json，跳过 TSC；请在目标前端项目根目录运行。"
else
  echo "✅ 未发现 TypeScript/Vue 目标文件"
fi

echo ""
echo "━━━ [2/3] ESLint 规则检查 ━━━"
if ! command -v npx >/dev/null 2>&1; then
  report_error "未找到 npx，无法运行 ESLint。"
elif has_matching_files; then
  if npx --yes eslint "$TARGET" \
    --ext .ts,.tsx,.vue \
    --rule '{"@typescript-eslint/no-explicit-any": "error"}' \
    --rule '{"no-magic-numbers": ["warn", {"ignore": [0, 1, -1]}]}' \
    --rule '{"max-params": ["warn", {"max": 2}]}' \
    --max-warnings 0 \
    --format stylish; then
    echo "✅ ESLint 通过"
  else
    report_error "ESLint 发现错误或警告"
  fi
else
  echo "✅ 未发现需要 ESLint 检查的目标文件"
fi

echo ""
echo "━━━ [3/3] 组件行数检查 ━━━"
if has_matching_files; then
  while IFS= read -r file_path; do
    line_count=$(wc -l < "$file_path" | tr -d ' ')
    if [ "$line_count" -gt "$MAX_COMPONENT_LINES" ]; then
      report_warning "$file_path 超过 ${MAX_COMPONENT_LINES} 行（${line_count} 行）→ 建议执行 Extract Component"
    fi
  done < <(find "$TARGET" -type f \( -name "*.tsx" -o -name "*.vue" \))
  echo "✅ 行数检查完成"
else
  echo "✅ 未发现组件文件"
fi

echo ""
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo "🎉 全部检查通过，代码符合 DFA 规范"
  exit 0
fi

echo "⚠️  发现 ${ERRORS} 处错误、${WARNINGS} 处警告，请参照 DFA 规则修正后重新生成"
exit 1
