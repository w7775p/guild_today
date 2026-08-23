# 《公会》协作流程

> 项目真源：https://app.notion.com/p/3c07fb71ada481ca8567e2e01efb05b1?pvs=204
> 同步时间：2026-08-18T09:19:01.507Z
> 职责：人与 AI 的开发流程、决策优先级、修改前后检查与汇报方式。
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
1. https://app.notion.com/p/3c07fb71ada481abb702fdf1a48e2eb3
2. https://app.notion.com/p/3c07fb71ada4813eb79dcfda505d78a6
3. https://app.notion.com/p/3c07fb71ada4819391eaefbecabc326e
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



## 7. 完成汇报
只汇报：
1. 改了什么；
2. 验证了什么；
3. 哪些内容仍未冻结 / 未完成；
4. 是否存在需要用户决策的问题。
不要重复完整实现过程。


## 附录 A：架构追溯与决策优先级
前序依据：
- https://app.notion.com/p/3bc7fb71ada481be9ce9dd51fde72a36：任务、结果、公会状态与运行时基础边界的前序冻结依据。
- https://app.notion.com/p/3bb7fb71ada4814888f9ea8e28e501d4：继续决定项目方向、产品验证顺序与策划边界。
- `角色卡策划原案.xlsx`：本轮角色数据结构候选方案的真实样本来源，目前只验证了埃利乌斯。
冲突处理：
1. 玩法、角色、任务创作内容冲突：回到对应策划真源，本页无权覆盖。
2. Godot 技术架构冲突：先判断本页内容属于“已冻结继承 / 正式变更 / 待验证 / 未冻结”哪一层。
3. 只有“已冻结继承”和“正式架构变更”可以覆盖更旧的技术结论。
4. “待验证方案”不得用于否定已冻结内容，也不得反向要求策划适配程序。

