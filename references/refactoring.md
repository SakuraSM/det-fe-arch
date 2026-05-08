# Refactoring 约束

本文件将《重构》中的核心原则转成 DFA 可执行规则：识别代码坏味道，用小步、可验证、行为保持的手法改善内部结构。

## 基本定义

重构只改变内部结构，不改变可观察行为。若用户同时要求新增功能和重构，必须拆成两个阶段：

1. 先做支持新功能的结构调整，并证明行为不变。
2. 再实现业务行为变化，并单独说明新增行为。

禁止把重命名、抽取、迁移和需求改动混在一个无法验证的大改里。

## 安全节奏

1. 建立保护：优先运行现有测试；没有测试时补特征测试、快照、类型检查或最小复现。
2. 定位坏味道：指出触发点，例如长函数、重复代码、霰弹式修改、依恋情结、数据泥团。
3. 选择最小手法：一次只应用一个明确的 refactoring。
4. 验证行为：每步后运行相关测试、类型检查或 lint。
5. 汇总变化：说明结构改善，不把行为变化伪装成重构。

## 坏味道到手法映射

| 坏味道 | 优先手法 |
|---|---|
| Duplicated Code 重复代码 | Extract Function、Pull Up Function、抽取共享配置 |
| Long Function 长函数 | Extract Function、Replace Temp with Query、Split Phase |
| Large Class / Large Component 大类或大组件 | Extract Class、Extract Component、Extract Hook、Extract Composable、Extract Module |
| Long Parameter List 长参数列表 | Introduce Parameter Object、Preserve Whole Object |
| Divergent Change 发散式变化 | Split Module、按变化原因拆分文件或组件 |
| Shotgun Surgery 霰弹式修改 | Move Function、Move Field、集中变化点 |
| Feature Envy 依恋情结 | Move Function，把行为移动到数据所属模块附近 |
| Data Clumps 数据泥团 | Introduce Parameter Object、Introduce Value Object |
| Primitive Obsession 基本类型偏执 | Replace Primitive with Object、Enum、Literal、值对象 |
| Switch / Conditional Complexity 条件复杂度 | Replace Conditional with Polymorphism、Strategy、Registry |
| Comments as Deodorant 注释掩盖复杂逻辑 | Extract Function，用命名表达意图 |
| Lazy Element 冗余抽象 | Inline Function、Inline Class、删除无收益层 |
| Speculative Generality 夸夸其谈未来性 | Collapse Hierarchy、删除未使用选项和扩展点 |

## 常用手法准则

### Extract Function

- 提取的函数名必须描述“做什么”，不要描述“怎么做”。
- 提取边界优先选择完整意图：校验、转换、分组、格式化、权限判断。
- 提取后参数超过 2 个时，继续考虑 Introduce Parameter Object。

### Split Phase

当一段逻辑同时做“解析输入、派生中间结构、执行业务动作”时拆成阶段：

1. 输入标准化。
2. 纯业务计算。
3. 副作用执行。

### Move Function

当函数频繁读取另一个模块或对象的数据，而很少使用自己所在模块的数据时，应移动到数据所属模块附近。

### Introduce Parameter Object

当同一组参数反复一起出现时，提取为具名对象，并在类型名中表达业务概念，不使用 `Params`、`Options` 这类空泛名称。

### Replace Conditional with Strategy / Registry

当条件分支表达可枚举行为差异时，使用策略表、组件注册表、命令映射或多态。不要为了两三个简单分支制造复杂继承。

## React / Vue / Python 落地

- React：优先 Extract Component、Extract Hook、提取纯 selector/formatter；保持 props 契约稳定。
- Vue 3：优先 Extract Component、Extract Composable、拆分模板条件；保持 `defineProps`、`defineEmits`、`defineModel` 契约稳定。
- Python：优先 Extract Function、Extract Module、Introduce dataclass/Pydantic model、Move Function；保持公共 API 和异常语义稳定。

## 禁止事项

- 不在重构提交里顺手修改业务语义、接口协议或视觉表现，除非用户明确要求。
- 不用“重构”名义删除测试覆盖不到但仍可能被调用的公共 API。
- 不为了抽象而抽象；重复结构但领域语义不同，可以暂不合并。
- 不用格式化 churn 淹没结构性 diff；若必须格式化，单独说明。
