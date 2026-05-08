# Clean Code 约束

本文件定义 DFA 的通用整洁代码规则，适用于 React、Vue 3 和框架无关的 TypeScript 代码。

## 语义化命名

命名必须表达领域含义，而不是表达实现细节或临时状态。

| 场景 | 反例 | 推荐 |
|---|---|---|
| 用户数据 | `data`, `u` | `userProfile`, `teamMember` |
| 布尔值 | `flag`, `visible` | `isDialogOpen`, `hasPermission` |
| 事件处理 | `handleClick` | `handleSubmitOrder`, `handleCloseDialog` |
| 集合 | `list` | `approvedRequests`, `navigationItems` |
| 配置 | `opts` | `paginationOptions`, `uploadConfig` |

禁止依赖上下文才能理解的命名。若变量离开当前函数后含义不清，必须重命名。

## 魔术值根除

业务数字、状态字符串、超时时间、分页大小、阈值、CSS 尺寸都应命名。

```ts
const MAX_VISIBLE_ITEMS = 5
const REQUEST_TIMEOUT_MS = 8000
const ORDER_STATUS_APPROVED = 'approved'
```

允许保留的非业务字面量：`0`、`1`、`-1`、空字符串、布尔值，以及数组索引相关的基础值。

## 函数单一职责

函数只能处在一个抽象层级。如果一个函数同时“请求数据、筛选数据、格式化文本、渲染 UI”，必须拆分。

```ts
interface UserSummary {
  id: string
  displayName: string
  roleLabel: string
}

function toUserSummary(user: User): UserSummary {
  return {
    id: user.id,
    displayName: `${user.firstName} ${user.lastName}`,
    roleLabel: ROLE_LABELS[user.role],
  }
}
```

## 参数对象化

3 个及以上参数必须合并为对象参数，并声明接口。

```ts
interface CreateUserInput {
  name: string
  email: string
  role: UserRole
  permissions: Permission[]
  teamId: string
}

function createUser(input: CreateUserInput): User {
  return buildUser(input)
}
```

## 条件复杂度重构

### 条件链反模式

```tsx
function Notification({ type }: { type: string }) {
  if (type === 'success') return <SuccessBanner />
  if (type === 'error') return <ErrorBanner />
  if (type === 'warning') return <WarningBanner />
  return null
}
```

### Registry 映射多态

```tsx
type NotificationType = 'success' | 'error' | 'warning'

const BANNER_REGISTRY: Record<NotificationType, React.FC> = {
  success: SuccessBanner,
  error: ErrorBanner,
  warning: WarningBanner,
}

function Notification({ type }: { type: NotificationType }) {
  const Banner = BANNER_REGISTRY[type]
  return <Banner />
}
```

## Guard Clauses

超过 3 层嵌套时，优先用前置返回降低缩进。

```ts
function canApproveRequest(input: ApprovalInput): boolean {
  if (!input.currentUser) return false
  if (!input.request.isPending) return false
  if (!input.currentUser.permissions.includes(APPROVE_PERMISSION)) return false

  return input.request.amount <= input.currentUser.approvalLimit
}
```

## DRY 的边界

重复逻辑出现第二次时应抽取；重复结构但业务语义不同，不要过早抽象。

优先级：

1. 抽取纯函数，保持无框架依赖。
2. 抽取 Hook 或 Composable，复用状态与副作用。
3. 抽取组件，复用 UI 结构。
4. 抽取配置或 Registry，复用映射关系。

## 死代码清理

- 删除未使用变量、函数、类型和导入。
- 删除被注释掉的旧实现；用版本控制追踪历史。
- 删除不可达分支；若为未来扩展，改为明确 TODO 并关联任务。
- 禁止保留“备用逻辑”和沉默 fallback。

## 文件与组件拆分

文件超过 300 行时必须评估拆分。类型声明和必要注释可不计入，但展示逻辑、状态管理、数据转换都计入复杂度。

拆分顺序：

1. 将纯数据转换提取到 `utils` 或同目录 helper。
2. 将状态副作用提取到 Hook/Composable。
3. 将独立视觉区块提取为子组件。
4. 将常量和 Registry 提取到明确命名的模块。
