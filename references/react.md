# React 架构约束

本文件适用于 React、JSX、TSX、Hooks、Context、memo、组件拆分和状态管理任务。

## 组件设计

- 组件名使用 PascalCase。
- Props 使用显式接口声明，接口名为 `ComponentNameProps`。
- 展示组件只负责渲染；数据请求和复杂状态迁移应提取到 Hook。
- JSX 中禁止复杂表达式、深层嵌套条件和大段映射逻辑。
- 列表 `key` 必须使用稳定业务 ID，禁止数组 index。

## 状态共置原则

状态应放在最接近使用它的位置。

| 状态类型 | 推荐位置 |
|---|---|
| 输入框临时值 | 当前表单组件 |
| 弹窗开关 | 拥有触发器的父组件或弹窗容器 |
| 请求缓存 | 数据层、query 库或专用 Hook |
| 跨页面用户信息 | 受限 Context 或 Store |
| 派生值 | `useMemo` 或普通计算，避免冗余 state |

禁止把只被一个子树使用的状态提升到全局 Store。

## Context API 约束

- Context 只用于真正跨层级共享的稳定数据。
- Provider 范围必须尽可能小。
- Context value 中包含对象或函数时必须使用 `useMemo` / `useCallback` 稳定引用。
- 高频更新状态不应直接放入大范围 Context，避免全树重渲染。

## Zustand 适用边界

适合：

- 跨页面共享的客户端状态。
- 与服务端缓存无关的 UI/业务状态。
- 多个远端组件需要读写同一状态。

不适合：

- 单组件局部 state。
- 可以从 props 派生的状态。
- 服务端数据缓存的唯一来源。

## Custom Hook 规范

- Hook 必须以 `use` 开头。
- Hook 只暴露必要状态和动作。
- 返回值必须有明确类型；多项返回优先对象而不是数组。
- 副作用依赖数组必须完整，禁止用禁用 lint 逃避依赖问题。

```ts
interface UseDialogResult {
  isOpen: boolean
  openDialog: () => void
  closeDialog: () => void
}

function useDialog(): UseDialogResult {
  const [isOpen, setIsOpen] = useState(false)

  const openDialog = useCallback(() => setIsOpen(true), [])
  const closeDialog = useCallback(() => setIsOpen(false), [])

  return { isOpen, openDialog, closeDialog }
}
```

## React.memo 决策树

```text
需要 React.memo 吗？
├── 是简单展示组件（< 5 个 DOM 节点）→ 不需要
├── 父组件频繁重渲染 + 子组件渲染昂贵 → 需要
│   └── 传入函数/对象 props？
│       ├── 是 → 必须搭配 useCallback / useMemo
│       └── 否 → 单独 React.memo 即可
└── 不确定 → 先 Profile，再决策
```

## useCallback / useMemo

使用条件：

- 回调传给 `memo` 子组件。
- 对象/数组传给 `memo` 子组件或 Context value。
- 计算成本明确较高。
- 引用稳定性影响 effect 依赖。

禁止为了“看起来优化”给所有函数套 `useCallback`。

## JSX 内联函数

默认避免在 JSX 中创建匿名函数，尤其是列表中。

```tsx
function UserRow({ user, onSelect }: UserRowProps) {
  const handleSelect = useCallback(() => {
    onSelect(user.id)
  }, [onSelect, user.id])

  return <button type="button" onClick={handleSelect}>{user.name}</button>
}
```

## 条件渲染

3 个及以上分支使用 Registry。

```tsx
const STATUS_BADGE_REGISTRY: Record<OrderStatus, React.FC> = {
  pending: PendingBadge,
  approved: ApprovedBadge,
  rejected: RejectedBadge,
}
```

## 虚拟滚动触发阈值

列表超过 `VIRTUALIZATION_ITEM_THRESHOLD`（默认 100）且单项渲染非平凡时，应考虑虚拟滚动。不要在小列表中引入虚拟滚动复杂度。

## 副作用

- `useEffect` 只处理副作用，不处理可同步计算的派生状态。
- 请求 effect 必须处理取消或过期响应。
- 清理函数必须释放监听器、定时器、订阅。
