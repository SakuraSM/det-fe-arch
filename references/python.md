# Python 约束

本文件定义 DFA 的 Python 代码生成、审查和重构规则，适用于服务端、CLI、脚本、数据处理和测试代码。

## 版本与项目约定

- 默认面向 Python 3.11+；若项目声明了更低版本，按项目版本选择兼容写法。
- 优先遵循已有 `pyproject.toml`、`ruff.toml`、`mypy.ini`、`pytest.ini`、`tox.ini` 或 `uv.lock`。
- 不引入新的运行时依赖，除非用户明确要求或现有项目已使用该依赖。
- 使用 `pathlib.Path` 处理路径，避免手写路径拼接。

## 类型与数据模型

公共边界必须类型明确：函数、方法、类属性、返回值、生成器、异步函数都要标注类型。

```py
from dataclasses import dataclass
from enum import StrEnum


class OrderStatus(StrEnum):
    APPROVED = "approved"
    REJECTED = "rejected"


@dataclass(frozen=True, slots=True)
class OrderSummary:
    order_id: str
    status: OrderStatus
    total_amount: int
```

- 简单不可变数据优先使用 `@dataclass(frozen=True, slots=True)`。
- API 入参、配置、环境变量或外部 JSON 边界优先使用项目既有校验方案；若已有 Pydantic，则使用 Pydantic 模型。
- 集合类型必须写元素类型，例如 `list[OrderSummary]`、`dict[str, int]`。
- 回调或结构化鸭子类型优先使用 `Protocol`，不要依赖隐式属性。

## 函数设计

- 函数保持单一职责；同一函数内不要混合 I/O、解析、业务判断和格式化输出。
- 3 个及以上业务参数必须合并为数据模型，或改为有明确名称的 keyword-only 参数。
- 有副作用的函数名必须表达动作，例如 `send_invoice_email()`、`persist_order_summary()`。
- 纯转换逻辑应提取为无副作用函数，便于单元测试。

```py
@dataclass(frozen=True, slots=True)
class CreateUserInput:
    name: str
    email: str
    role: str
    team_id: str


def create_user(user_input: CreateUserInput) -> User:
    return build_user(user_input)
```

## 错误处理与日志

- 禁止裸 `except:`；只捕获可恢复的具体异常。
- 不吞错，不返回伪成功默认值；需要降级时必须记录原因并返回明确的失败形状。
- 库代码使用 `logging.getLogger(__name__)`，不要用 `print()` 做业务日志。
- 对外部系统错误包装为领域异常时，保留原异常链：`raise DomainError(...) from error`。
- 资源必须用上下文管理器管理，例如文件、锁、数据库连接和临时目录。

## 异步与并发

- `async` 函数内部不得调用阻塞 I/O；必要时使用项目既有线程池或异步客户端。
- 并发任务必须有超时、取消和异常收敛策略。
- 不在库函数里直接创建全局事件循环；由应用入口负责调度。

## 测试

- 新增业务分支必须补充 pytest 测试，优先覆盖正常路径、边界值和错误路径。
- 对文件系统、时间、随机数、网络和数据库使用 fixture 或依赖注入隔离。
- 测试名描述行为，例如 `test_rejects_order_when_amount_exceeds_limit()`。
- 不用真实外部服务作为单元测试依赖。

## Python 反模式

| 反模式 | 替代方案 |
|---|---|
| 裸 `dict` 在多层函数间传递 | `dataclass`、`TypedDict`、Pydantic 模型 |
| 魔术字符串状态 | `Enum`、`Literal`、常量映射 |
| `Any`、`cast()`、`type: ignore` 快速绕过 | 补齐类型、引入 `Protocol` 或边界校验 |
| 宽泛 `except Exception` 后静默返回 | 捕获具体异常、记录上下文、显式失败 |
| 大型脚本顶层执行复杂逻辑 | `main()` + 小函数 + `if __name__ == "__main__"` |
| 直接拼接 SQL | 参数化查询或项目 ORM/query builder |

## 质量门禁

修改 Python 代码后运行：

```bash
scripts/lint-check.sh <目标路径>
```

脚本会在工具可用时执行：

1. `ruff check`
2. `mypy --strict`

若目标项目没有配置 Ruff 或 Mypy，必须在回复中说明已跳过的检查和残余风险。
