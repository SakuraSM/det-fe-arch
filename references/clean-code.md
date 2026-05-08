# Clean Code 约束

本文件定义 DFA 的通用整洁代码规则，适用于 React、Vue 3、TypeScript 和 Python 代码。

## 原则覆盖

本文件遵循《代码整洁之道》的核心方向：命名表达意图、函数短小单一、避免隐藏副作用、错误路径清晰、边界隔离、测试可读、持续清理。输出代码时必须优先让读者理解业务意图，而不是炫示技巧或框架细节。

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

命名补充规则：

- 同一概念只使用一个词，例如不要混用 `fetch`、`get`、`load` 表达同一类读取行为。
- 不用类型、容器或实现细节命名业务对象，例如 `userListData`、`orderObj`。
- 不使用误导性名称；名称不能暗示不存在的排序、缓存、远程请求或副作用。
- 作用域越大，名称必须越完整；短作用域局部变量也必须能表达意图。

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

函数必须短小、可命名、可测试：

- 函数主体优先控制在一个屏幕内；超过 30 行必须评估 Extract Function 或 Split Phase。
- 函数内部保持同一抽象层级，禁止高层业务流程和底层字段拼装交错。
- 查询函数不产生副作用；命令函数不伪装成查询。若函数会写入、发送、缓存或埋点，函数名必须暴露动作。
- 不使用输出参数修改调用方传入对象；返回新值或显式调用领域命令。
- 布尔参数会隐藏两个执行路径，优先拆成两个命名函数或使用明确的参数对象。

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

对象参数必须表达业务概念。禁止把参数对象命名为 `Params`、`Options`、`Config` 后继续塞入不相关字段；若字段因不同原因变化，继续拆分为多个输入模型。

## 错误处理

- 使用异常或明确失败结果表达错误，不返回 `null`、`undefined`、空数组或默认对象伪装成功。
- 错误处理不能打断主流程可读性；复杂错误恢复逻辑应提取为命名函数。
- 捕获异常必须处理具体类型、补充上下文或向上抛出；禁止吞错。
- 公共边界要区分用户可恢复错误、系统错误和编程错误。
- 清理资源必须使用 `finally`、上下文管理器或框架生命周期，不能依赖调用方猜测。

## 边界封装

- 第三方 SDK、浏览器 API、存储、网络、日期时间、随机数等不稳定边界必须封装在 adapter/service 层。
- 业务代码不得散落第三方响应结构；进入核心逻辑前先转换为领域模型。
- 对外部输入先校验再使用，禁止把未知结构直接传进渲染、计算或持久化逻辑。

## 注释规则

注释只能解释代码无法直接表达的意图、约束或取舍；不能复述代码做了什么。

- 优先通过重命名、提取函数、拆分模块删除解释性注释。
- 保留约束性注释，例如协议兼容、性能边界、安全原因、浏览器/平台缺陷。
- 删除过期注释、注释掉的旧代码和没有任务编号的 TODO。
- 公共 API 注释必须说明契约和异常语义，不写实现流水账。

## 条件复杂度重构

重构任务必须同时参考 `references/refactoring.md`，先确认坏味道，再选择行为保持的小步手法。

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

## 类、模块与组件组织

- 一个模块只围绕一个变化原因组织；不同变化节奏的职责必须拆开。
- 类或组件应小而内聚；字段、状态、方法应服务同一个领域概念。
- 优先组合而非继承；继承只用于稳定的真正层级关系。
- 文件对外暴露面越小越好，只导出必要 API。
- 依赖方向从业务策略指向稳定抽象，不让底层工具反向牵引业务模型。

## 死代码清理

- 删除未使用变量、函数、类型和导入。
- 删除被注释掉的旧实现；用版本控制追踪历史。
- 删除不可达分支；若为未来扩展，改为明确 TODO 并关联任务。
- 禁止保留“备用逻辑”和沉默 fallback。

## 测试整洁

- 测试代码和生产代码一样需要清晰命名、单一断言意图和低重复。
- 每个测试只表达一个行为原因；Arrange、Act、Assert 边界必须清楚。
- 测试不依赖执行顺序、真实时间、真实网络或共享全局状态。
- 测试 fixture 必须服务行为语义，不堆砌无关字段。
- 修复 bug 时优先补回归测试；重构前优先建立行为保护。

## 格式与局部整洁

- 遵循项目 formatter，不做无关格式化 churn。
- 垂直距离体现概念距离：相关声明靠近，不相关职责拆开。
- import 顺序、常量位置、类型位置按项目惯例统一。
- 每次修改遵守 Boy Scout Rule：只清理触达范围内的小问题，不扩大无关重构。

## 文件与组件拆分

文件超过 300 行时必须评估拆分。类型声明和必要注释可不计入，但展示逻辑、状态管理、数据转换都计入复杂度。

拆分顺序：

1. 将纯数据转换提取到 `utils` 或同目录 helper。
2. 将状态副作用提取到 Hook/Composable。
3. 将独立视觉区块提取为子组件。
4. 将常量和 Registry 提取到明确命名的模块。
