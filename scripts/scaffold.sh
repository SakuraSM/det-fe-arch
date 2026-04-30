#!/usr/bin/env bash
# DFA 组件脚手架 - 基于规范模板生成初始结构。
# 用法: ./scripts/scaffold.sh react UserCard
#      ./scripts/scaffold.sh vue ProductList
set -euo pipefail

FRAMEWORK=${1:-}
NAME=${2:-}
OUTPUT_DIR=${OUTPUT_DIR:-src/components}

usage() {
  echo "用法: ./scripts/scaffold.sh [react|vue] ComponentName"
}

if [ -z "$FRAMEWORK" ] || [ -z "$NAME" ]; then
  usage
  exit 1
fi

if ! [[ "$NAME" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
  echo "❌ 组件名必须使用 PascalCase，例如 UserCard"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

replace_component_name() {
  local source_file=$1
  local destination_file=$2
  sed "s/ComponentName/${NAME}/g" "$source_file" > "$destination_file"
}

case "$FRAMEWORK" in
  react)
    DESTINATION="$OUTPUT_DIR/${NAME}.tsx"
    if [ -e "$DESTINATION" ]; then
      echo "❌ 目标文件已存在：$DESTINATION"
      exit 1
    fi
    replace_component_name "templates/react-component.tsx" "$DESTINATION"
    echo "✅ React 组件已生成：${DESTINATION}（符合 DFA 模板规范）"
    ;;
  vue)
    DESTINATION="$OUTPUT_DIR/${NAME}.vue"
    if [ -e "$DESTINATION" ]; then
      echo "❌ 目标文件已存在：$DESTINATION"
      exit 1
    fi
    replace_component_name "templates/vue-component.vue" "$DESTINATION"
    echo "✅ Vue 3 组件已生成：${DESTINATION}（符合 DFA 模板规范）"
    ;;
  *)
    echo "❌ 不支持的框架：$FRAMEWORK（支持 react / vue）"
    usage
    exit 1
    ;;
esac
