# Vue 3 架构约束

本文件适用于 Vue 3、SFC、Composition API、`<script setup>`、`defineModel`、Composable 和模板重构任务。

## `<script setup>` 强制规范

- 新建 Vue 3 组件必须使用 `<script setup lang="ts">`。
- Props、Emits、Model、Slots 类型必须显式声明。
- 常量、类型、Composable 调用、computed、watch 按职责分组。
- 禁止 Options API 与 Composition API 混写，迁移任务除外。

## ref / reactive 使用法则

| 数据类型 | 推荐 API |
|---|---|
| string / number / boolean | `ref` |
| 数组整体替换频繁 | `ref<T[]>` |
| 嵌套对象表单 | `reactive` |
| 外部只读暴露 | `readonly` |
| 派生值 | `computed` |

在 `<script setup>` 中访问 `ref` 必须使用 `.value`；模板中不需要 `.value`。

## computed 必用场景

- 从 props 或 state 派生展示值。
- 过滤、排序、格式化后的列表。
- 按权限、状态、配置计算可见性。

禁止把派生值存入额外 state，除非需要快照语义。

## watch / watchEffect 限制

- `watch` 用于响应明确数据源变化并执行副作用。
- `watchEffect` 仅用于依赖简单且可自动收集的副作用。
- 禁止用 watch 同步两个可由 computed 表达的值。
- 异步 watch 必须处理过期请求或清理逻辑。

```ts
watch(searchKeyword, async (keyword, _previousKeyword, onCleanup) => {
  const controller = new AbortController()
  onCleanup(() => controller.abort())

  await fetchSearchResults(keyword, { signal: controller.signal })
})
```

## defineModel 用法

Vue 3 新组件双向绑定优先使用 `defineModel()`，不要回退到 `modelValue` + `update:modelValue`。

```vue
<script setup lang="ts">
const rating = defineModel<number>({ required: true })
const comment = defineModel<string>('comment', { default: '' })
</script>
```

修饰符：

```vue
<script setup lang="ts">
const [title, titleModifiers] = defineModel<string, 'trim'>('title')
</script>
```

## Composable 设计契约

- 命名必须以 `use` 开头。
- 输入参数必须有类型，3 个及以上参数改为对象。
- 返回对象应暴露 `readonly` 状态和命名动作。
- 副作用必须在作用域销毁时清理。

```ts
interface UseCounterResult {
  count: Readonly<Ref<number>>
  increment: () => void
  reset: () => void
}

function useCounter(): UseCounterResult {
  const count = ref(0)
  const increment = (): void => {
    count.value += 1
  }
  const reset = (): void => {
    count.value = 0
  }

  return { count: readonly(count), increment, reset }
}
```

## 模板规则

- `v-if` 和 `v-for` 禁止放在同一标签。
- 列表 `:key` 必须使用稳定业务 ID，禁止 index。
- 复杂表达式提取为 computed 或方法。
- 交互元素必须使用语义化 HTML。
- 事件处理函数命名表达业务意图。

```vue
<template>
  <template v-if="hasVisibleItems">
    <article v-for="item in visibleItems" :key="item.id">
      {{ item.title }}
    </article>
  </template>
</template>
```

## Style Guide Priority A/B 执法清单

Priority A：

- 组件名使用多词命名。
- Props 定义尽量详细，避免裸数组形式。
- `v-for` 必须有 key。
- 禁止 `v-if` 与 `v-for` 同元素。
- Scoped 样式或 CSS Modules 控制样式作用域。

Priority B：

- 组件文件名使用 PascalCase。
- 模板表达式保持简单。
- 指令缩写风格保持一致。
- 复杂列表渲染拆分子组件。

## 样式与作用域

- SFC 样式默认使用 `scoped`。
- 焦点样式必须可见。
- 颜色变量需满足对比度规则。
- 组件不应依赖全局样式才能正确显示核心状态。
