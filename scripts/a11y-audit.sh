#!/usr/bin/env bash
# DFA A11y 扫描 - 基于 axe-core 检查 WCAG AA 合规性。
# 用法: ./scripts/a11y-audit.sh [URL，默认 http://localhost:5173]
set -euo pipefail

URL=${1:-"http://localhost:5173"}

if ! command -v npx >/dev/null 2>&1; then
  echo "❌ 未找到 npx，请先安装 Node.js/npm。"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ 未找到 jq，请先安装 jq 后重试。"
  exit 1
fi

echo "━━━ DFA A11y 审计 - $URL ━━━"

AUDIT_OUTPUT=$(npx --yes @axe-core/cli "$URL" --tags "wcag2a,wcag2aa" --reporter json)
VIOLATION_COUNT=$(printf '%s' "$AUDIT_OUTPUT" | jq '.violations | length')

if [ "$VIOLATION_COUNT" -eq 0 ]; then
  echo "✅ 未发现 WCAG A/AA 违规"
  exit 0
fi

printf '%s' "$AUDIT_OUTPUT" | jq '
  .violations[] |
  {
    rule: .id,
    impact: .impact,
    description: .description,
    help: .help,
    helpUrl: .helpUrl,
    nodes: [.nodes[].html]
  }
'

echo "⚠️  发现 ${VIOLATION_COUNT} 条 A11y 违规，请修复 critical/serious 后重试"
exit 1
