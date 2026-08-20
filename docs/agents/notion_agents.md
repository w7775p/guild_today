# 《公会》AGENTS.md

> 本文件是 Notion 项目真源的本地工作镜像。
>
> 来源：https://app.notion.com/p/3c07fb71ada481ca8567e2e01efb05b1?pvs=204
>
> 同步时间：2026-08-18T09:19:01.507Z
>
> 用途：AI 协作规则；开发流程；决策优先级。

## Notion 页面属性

```json
{
  "date:最后核对日期:is_datetime": 0,
  "date:最后核对日期:start": "2026-08-18",
  "url": "https://app.notion.com/p/3c07fb71ada481ca8567e2e01efb05b1",
  "一句话用途": "Godot 新仓库的 Agent 工作入口；只规定读取顺序、当前开发边界、修改与验证流程，并指向正式架构、工程铁律和 known_traps。",
  "名称": "《公会》[AGENTS.md](http://AGENTS.md)",
  "文档类型": "主文档",
  "最近编辑": "2026-08-18T09:19:01.386Z",
  "状态": "当前使用",
  "真源级别": "有效参考",
  "类型": "规则",
  "说明": "仓库根 [AGENTS.md](http://AGENTS.md) 的 Notion 镜像。自身不定义策划或技术架构；发生冲突时服从策划真源、Godot正式开发架构和正式工程铁律。",
  "重要度": "核心",
  "页面成熟度": "暂时冻结",
  "项目": "公会今日照常营业",
  "领域": "游戏开发"
}
```

## Notion 原始层级

```text
<parent-data-source url="collection://2927fb71-ada4-8029-8ebe-000b0239169a" name="个人知识/数据库"/>
<ancestor-2-database url="https://app.notion.com/p/2927fb71ada48014b856fed0516676ad" title=""/>
```

## 正文

<content>
> 本页对应新 Godot 仓库根目录 `AGENTS.md`。只规定 Agent 的工作入口与执行流程，不定义游戏设计，不替代架构或工程规范。
## 1. 当前阶段
项目阶段：**概念验证与前期创作**。
当前技术工作：**Godot 最小垂直切片验证**。
当前验证闭环：
```plain text
阅读委托与角色
→ 选择并派遣
→ 等待 / 执行中
→ 任务判定
→ Result
→ 结算
→ 阅读报告
→ 状态变化进入后续判断
```
## 2. 开工前读取顺序
1. <mention-page url="https://app.notion.com/p/3c07fb71ada481abb702fdf1a48e2eb3"/>
2. <mention-page url="https://app.notion.com/p/3c07fb71ada4813eb79dcfda505d78a6"/>
3. <mention-page url="https://app.notion.com/p/3c07fb71ada4819391eaefbecabc326e"/>
4. 与本次任务直接相关的代码、测试和资产
### 权责优先级
- **产品、角色、任务等策划内容**：用户最新明确决定 / 对应策划真源与本地正式工作案优先。
- **Godot 技术架构**：Godot正式开发架构中的“已冻结继承 / 正式架构变更”优先。
- **实现纪律**：正式工程铁律优先。
- **当前代码**：只能证明现状，不能覆盖更高层真源。
- `TEST_ONLY` 内容不得反向冻结正式 Schema。
## 3. 当前允许开发
仅限当前冻结的技术切片：
- `GameSession`
- `GuildState / StateValue`
- `TaskSystem / TaskInstance`
- `DispatchSystem / DispatchInstance`
- `TaskResolutionSystem`
- `ResultSettlementSystem`
- `StateRelationshipSystem` 壳
- `ReportIntelSystem` 壳
- `SaveSystem` 壳
- 已确认的静态 Resource 类型声明；**不得因此补全未冻结字段 Schema**
- GdUnit4 自动测试
- 核心循环 UI 壳
- `TEST_ONLY` 测试资产
## 4. 当前阶段禁止擅自引入
除非真实需求出现并重新冻结，否则不要引入：
- 通用 `RuleEngine / Condition / Effect / Flag` DSL
- TimeSystem / 日历 / 每日刷新框架
- 完整 Inventory / Facility / Economy 扩展系统
- Godot JSON Importer / 自定义 Data Editor
- 万能 Manager / ServiceLocator / EventBus
- 为未来需求提前创建的抽象层
- 由 fixture 反向定义的正式 Character / Task / Result Schema
- 第二真相源
## 5. 修改前
修改公开 API、Signal、ID、Resource 字段、生命周期或系统职责前：
1. 确认状态拥有者。
2. 追踪创建方、调用方、读取方和消费方。
3. 确认是否触碰未冻结区域。
4. 确认已有相关测试。
## 6. 修改后
1. 对修改的 `.gd` 执行对应 parse / `--check-only --script` 检查。
2. 运行相关 GdUnit4 测试。
3. 重命名后搜索旧 ID / 方法 / Signal 残留。
4. 检查 `git diff`，只保留本次必要改动。
5. 对照 known_traps 做同类陷阱自查。
不得以“项目能启动”代替单文件检查和相关测试。
## 7. Godot 生命周期提醒
- Autoload 名称不得与 `class_name` 冲突。
- 新增 Autoload 后核对 `project.godot`。
- `PackedScene.instantiate()` 后，节点未进入树时不得假设 `@onready` 已初始化。
- 关键 Task / Dispatch 清理必须显式完成，不依赖 `_exit_tree()` 等销毁副作用。
- UI 只提交请求和显示事实，不直接写业务状态。
## 8. TEST_ONLY
- ID 统一 `test_` 前缀。
- 放入 `tests/fixtures/`。
- 第一阶段判定保持确定性。
- 正式运行路径可以消费 fixture，但不得为 fixture 另建第二套业务流程。
- fixture 字段不得自动升级为正式策划或 Runtime Schema。
## 9. Git
- 未经用户明确指令：**禁止 push**。
- 提交前确认 scope，不混入无关文件。
## 10. 完成汇报
只汇报：
1. 改了什么；
2. 验证了什么；
3. 哪些内容仍未冻结 / 未完成；
4. 是否存在需要用户决策的问题。
不要重复完整实现过程。
</content>
