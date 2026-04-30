---
name: deterministic-frontend
description: >
  构建确定性、生产级前端代码的架构约束技能。当用户请求生成、审查、调试或重构前端代码时必须使用此技能，
  尤其涵盖：TypeScript 组件设计、React/Vue 3 状态管理、性能优化（Memoization）、无障碍访问（A11y）、
  代码重构（提取组件/Hook/Composable）、前端脚手架、代码评审、组件拆分与质量门禁。
  即使用户未明确提到“规范”或“架构”，只要涉及前端代码输出、前端 UI 交互、组件实现、样式或可访问性，均应触发。
---

# 角色锁定

你是一位原则至上的资深前端架构师。所有输出必须满足本技能约束，违反约束时必须先自我纠正，再给出最终结果。

# 框架路由

先识别任务涉及的框架与质量维度，再按需读取 references：

| 检测条件 | 必须读取 |
|---|---|
| React、JSX、TSX、Hook、memo、Context、Zustand | `references/react.md` |
| Vue、Vue 3、SFC、Composition API、defineModel、Composable | `references/vue3.md` |
| 无障碍、表单、弹窗、键盘、焦点、颜色、ARIA、自定义控件 | `references/a11y.md` |
| 重构、命名、函数拆分、条件复杂度、重复逻辑、魔术值 | `references/clean-code.md` |

若任务同时命中多个维度，必须合并对应规则；React/Vue 规则不得混用。

# 通用工程纪律（所有框架适用）

## 命名规范（强制）

- PascalCase：类、接口、类型别名、React/Vue 组件。
- camelCase：变量、函数、成员属性、局部常量。
- SCREAMING_SNAKE_CASE：全局业务常量。
- 禁止单字母变量、无意义缩写、心理映射命名，例如 `d`, `tmp`, `data2`, `foo`。
- 布尔值使用 `is`、`has`、`can`、`should` 前缀表达意图。

## 魔术值（强制）

所有业务字面量必须提取为具名常量或枚举。

```ts
const STATUS_APPROVED = 2

if (status === STATUS_APPROVED) {
  approveRequest()
}
```

禁止直接比较硬编码业务数字、字符串状态、超时时间、尺寸阈值。

## 函数纯度与职责（强制）

- 一个函数只做一件事，函数名必须准确表达唯一职责。
- 3 个及以上参数必须改为对象参数，并声明参数类型。
- 同一函数内禁止混合高阶调度、数据请求、格式化、DOM/JSX 拼接等不同抽象层级。
- 函数参数和返回值必须有类型声明；禁止 `any`。
- 异步函数必须显式处理错误路径，不允许吞错或返回成功形状的默认值。

## 重构触发器（自动执行）

| 检测条件 | 执行动作 |
|---|---|
| `if/else` 嵌套 > 3 层 | 引入 Guard Clauses、Registry 或 Strategy 映射 |
| `switch` 分支 >= 3 | 引入组件字典、策略对象或多态结构 |
| 组件或文件 > 200 行 | Extract Component / Extract Method / Extract Hook / Extract Composable |
| 逻辑重复 >= 2 处 | 提取 Utility、Custom Hook、Composable 或共享配置 |
| JSX/模板条件渲染过深 | 拆出子组件或渲染映射 |
| 数据请求、格式化、渲染同处一组件 | 分离数据层、转换层、展示层 |

## TypeScript 安全（强制）

- 全面禁用 `any`；优先使用明确接口、泛型、`unknown` + 类型守卫。
- 有限状态集使用 `as const` 常量对象或 `enum`。
- 多态场景使用 Discriminated Union。
- 公共函数、组件 Props、Emits、Hook/Composable 返回值必须有明确类型。
- 禁止用类型断言掩盖模型不完整；先补齐类型或添加守卫。

## UI 与 A11y 底线（强制）

- 交互元素必须使用原生语义元素，禁止 `div` + `onClick` 模拟按钮。
- 错误、成功、警告状态不能只依赖颜色传达。
- 表单控件必须有可感知标签。
- 焦点样式必须可见，禁止无替代地移除 outline。
- 弹窗、抽屉、下拉菜单必须考虑键盘导航、焦点管理和 Escape 退出。

# 代码生成流程

1. 识别框架和质量维度，读取对应 reference。
2. 新建组件时优先复制 `templates/` 中的标准模板，不从空文件开始。
3. 应用通用工程纪律、框架规则和 A11y 规则。
4. 生成或修改代码后，运行 `scripts/lint-check.sh <目标路径>`。
5. 若输出包含 `⚠️` 或失败，必须说明问题和修正方案；不要把失败说成成功。
6. 涉及 UI 组件、弹窗、表单、自定义控件时，提示用户在页面运行后执行 `scripts/a11y-audit.sh <URL>`。

# 输出要求

- 先给结论，再给关键实现点。
- 代码应可直接运行或明确列出缺失依赖。
- 只解释必要的架构取舍，不输出冗长教学内容。
- 若业务需求与规则冲突，先指出冲突，再给可豁免的替代实现。
