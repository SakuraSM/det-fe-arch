# Deterministic Frontend Architect

DFA（Deterministic Frontend Architect）把工程最佳实践沉淀为 Agent Skill、参考规则、脚本和模板，用于约束 AI 生成的 React/Vue 3/TypeScript/Python 代码。

## 目标

- 减少 LLM 生成前端代码时的命名混乱、职责耦合、魔术值和框架反模式。
- 对 React、Vue 3、Python、A11y、Clean Code 提供可按需加载的规则集。
- 通过脚本执行 TypeScript、ESLint、Ruff、Mypy、行数和 A11y 后置检查。
- 通过模板让新组件默认具备类型安全、语义化 HTML 和可访问焦点样式。

## 目录结构

```text
.
├── SKILL.md
├── references/
│   ├── clean-code.md
│   ├── a11y.md
│   ├── python.md
│   ├── react.md
│   └── vue3.md
├── scripts/
│   ├── lint-check.sh
│   ├── scaffold.sh
│   └── a11y-audit.sh
├── templates/
│   ├── react-component.tsx
│   └── vue-component.vue
├── evals/
│   ├── test-cases.json
│   └── assertions.json
├── package.json
└── tech-doc.md
```

## 使用方式

### 作为 Skill 使用

将仓库内容安装到支持 Skill 的 Agent 环境中。触发前端生成、审查、重构、A11y 或框架架构任务时，Agent 应读取 `SKILL.md`，再按路由读取 `references/` 中的对应规则。

### 生成组件模板

```bash
./scripts/scaffold.sh react UserCard
./scripts/scaffold.sh vue ProductList
```

默认输出到 `src/components`。可通过 `OUTPUT_DIR` 覆盖：

```bash
OUTPUT_DIR=app/components ./scripts/scaffold.sh react UserCard
```

### 运行质量门禁

在目标前端项目根目录运行：

```bash
./scripts/lint-check.sh src/components/UserCard.tsx
```

检查内容：

1. `tsc --noEmit --strict`
2. ESLint 规则：禁止 `any`、魔术数字告警、参数数量告警
3. Python 规则：可用时执行 `ruff check` 和 `mypy --strict`
4. `.tsx` / `.vue` 组件 300 行阈值检查

### 运行 A11y 审计

先启动目标页面，再运行：

```bash
./scripts/a11y-audit.sh http://localhost:5173
```

脚本使用 `@axe-core/cli` 和 `jq` 输出 WCAG A/AA 违规详情。

## 本地校验

```bash
npm install
npm run check
```

`npm run check` 会校验 JSON 文件和 shell 脚本语法。前端项目级 ESLint、TypeScript 和 A11y 扫描应在目标项目中运行。

## 依赖要求

- Node.js >= 16（A11y 审计依赖的浏览器工具链建议使用 Node.js >= 18）
- npm >= 8
- Python 3.11+（Python 项目检查建议安装 Ruff 和 Mypy）
- bash
- `jq`（仅 `scripts/a11y-audit.sh` 需要）

## 规则覆盖

| 维度 | 文件 | 重点 |
|---|---|---|
| 通用工程纪律 | `SKILL.md`、`references/clean-code.md` | 命名、魔术值、职责拆分、重构触发器、类型安全 |
| React | `references/react.md` | 状态共置、Context 范围、Hook 契约、memo 决策、稳定 key |
| Vue 3 | `references/vue3.md` | `<script setup>`、`defineModel`、Composable、模板规则、Style Guide A/B |
| Python | `references/python.md` | 类型标注、数据模型、异常处理、异步边界、pytest、Ruff/Mypy |
| A11y | `references/a11y.md` | 语义化 HTML、ARIA 边界、键盘导航、Focus Trap、表单错误 |

## 评测

`evals/test-cases.json` 提供覆盖 clean code、重构、A11y、框架和 Python 约束的测试 Prompt。`evals/assertions.json` 定义对应断言，可用于人工评审或自动化评测。

## 打包

生成 `.skill` 包：

```bash
zip -r deterministic-frontend.skill SKILL.md references scripts templates evals README.md package.json tech-doc.md
```

打包前建议运行 `npm run check` 并确认脚本具备执行权限。
