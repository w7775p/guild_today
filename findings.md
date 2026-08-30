# 当前关键发现

## 当前决策

- Resource 只保存静态定义；Runtime/Instance 保存已发生事实；System 管理运行逻辑。
- Godot 4.7.2 验证程序固定使用 `D:\steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`，避免当前 shell 的 PATH 差异造成“找不到可执行文件”。
- 派遣成员真源是 `DispatchInstance.character_refs[]`。
- 不引入通用 RuleEngine、DSL、EffectExecutor、随机或隐式优先级。
- ResultGroup 必须唯一命中一个 ResultAsset。
- Task 3 的状态拥有者按 `task_plan.md` 冻结的最小边界执行；效果无法安全归属时暂停做架构决策。

## 当前真实内容

- 第一任务：`task_missing_caravan`。
- 第一结果组：`result_group_missing_caravan`。
- 五个结果稳定 ID：
  - `result_missing_caravan_full_success`
  - `result_missing_caravan_delayed_success`
  - `result_missing_caravan_injured_rescue`
  - `result_missing_caravan_location_confirmed`
  - `result_missing_caravan_search_failed`
- 本地 Notion 快照属于“测试用 v1”；Jackie 已确认未冻结文本和 ID 使用唯一语义占位符，无需阻塞实现。
- 角色池六人记录按当前测试资料使用，阿斯特里德职业采用“魔剑士”。
- 任务池与结果组池差异属于测试资料状态未同步，当前以结果组池已有稳定 ID 和项目资产为准。

## Task 3 已知效果口径

- 结果效果由具体 Resource 表达，结算系统仅把效果交给对应状态拥有者写入；没有引入通用效果执行器。
- `GuildState` 持有金币与总声望；`StateRelationshipSystem` 持有关系变化；`CharacterStateSystem` 持有伤势；`ReportIntelSystem` 持有情报解锁与报告记录；`TaskSystem` 持有任务终态。
- `ResultSettlementSystem.settle_result()` 在状态写入前检查所需拥有者与目标，继续按派遣 ID 拒绝重复结算。
- 五个正式结果均已接入效果：完整成功 90 金币；延迟成功 60 金币并附伤势；带伤救回附伤势；查明位置附情报/解锁；搜索失败附关系下降。

- 完整成功：90 金币、商人评价上升已确认；评价数值、状态 ID、任务终态、完整报告未定。
- 延迟成功：幸存者获救、伤势恶化、部分货物转移、部分报酬、治疗/追赃方向已确认；金额未定。
- 带伤救回：实际参与角色受伤、伤势在结算时确定已确认；受伤目标规则和等级未定。
- 查明位置：位置与幸存者状态情报已确认；任务终态和后续稳定资产引用未定，快照明确“无稳定资产引用”。
- 搜索失败：任务失败、商人信任下降已确认；信任数值、状态 ID、完整报告未定。

## 占位与推测

### 唯一语义占位符

- 五个任务终态：`【task_outcome_full_success】`、`【task_outcome_delayed_success】`、`【task_outcome_injured_rescue】`、`【task_outcome_location_confirmed】`、`【task_outcome_search_failed】`。
- 关系状态：`【relationship_merchant_evaluation】`、`【relationship_merchant_trust】`。
- 情报与后续任务：`【intel_missing_caravan_location】`、`【task_missing_caravan_followup_rescue】`。
- 五份报告：使用 `【report_missing_caravan_<result>】` 形式分别占位。
- 以上占位符只表示策划未冻结，后续由正式策划 ID 或文本直接替换。

### 工作性推测，均未视为正式策划

- 延迟奖励：60 金币。
- 完整成功评价：`+5`。
- 搜索失败信任：`-5`。
- 受伤目标：实际参与队伍中战斗能力最高的角色。
- 伤势等级：1。
- 查明位置：当前任务部分完成，并保留救援 ID `【task_missing_caravan_followup_rescue】`。

以上数值与伤势规则中除 90 金币外均为工作性推测，后续允许直接替换。

## Task 3 验证结论

- 五个结果的状态写入、报告保存、按派遣读取和重复结算拒绝均通过专项测试。
- Task 1/2 与 V2 `runtime_chain` 回归通过；Task 3 没有改变结果判定规则。
- 附加 `vertical_slice_test.tscn` 输出全部既有成功信息，但该场景没有自动退出，因此手动终止且不计入自动通过项。

## Task 4 验证结论

- `DaySystem` 只持有整数 `current_day`，日期推进通过 `day_advanced` 通知，不直接写入任务、派遣、结果或公会状态。
- 定时派遣的到期事实由 `DispatchInstance.started_day`、`due_day`、`ended_day` 持有；角色占用从 ACTIVE 派遣推导，显式结束后释放。
- `ResultSettlementSystem` 在定时派遣到期前拒绝结算；缺少当前日期也拒绝定时派遣结算。
- Task 4 专项、Task 1/2/3 与 V2 `runtime_chain` 回归均通过；负向结算分支的 ERROR 为测试预期输出。

## Task 5 验证结论

- 正式 `GameSession` 只编排现有状态拥有者；角色占用、金币、日期、结果和报告仍由对应 System 持有。
- `GameSession` 加载六名正式角色与首张任务，不读取 `tests/fixtures/`，也不注册为 Autoload。
- 完整成功、查明位置、搜索失败三条路线均完成两日等待、唯一判定、结算、报告、派遣结束和角色释放。
- Task 5 正常专项业务错误输出为 0；Task 3/4 与 V2 `runtime_chain` 回归通过，Godot 环境告警另列。

## Task 6 验证结论

- 核心循环 UI 只通过 `GameSession` 查询状态和提交命令，没有直接写入 Task、Dispatch、Guild、Character 或 Report 字段。
- `GameSession.validate_dispatch()` 提供玩家可见失败原因；界面确认按钮仅在 1–2 名合法角色时启用。
- 报告进入独占阅读态，展示结果 ID、派遣队伍最高能力和已结算后果；关闭只修改报告阅读状态。
- Task 6 专项、正式主场景启动、Task 5 与 V2 `runtime_chain` 回归均通过；业务错误输出为 0，Godot 环境告警另列。

## Task 7 数值覆盖前置结论

- 六名正式角色全部可以加载，Task 6 已证明正式主场景可操作。
- 按正式队伍取最高能力值枚举 6 个单人派遣与 15 个双人派遣：完整成功 11 种、延迟成功 4 种、查明位置 3 种、搜索失败 3 种、带伤救回 0 种。
- “带伤救回”要求调查能力至少 5 且战斗能力为 4–5。调查达到 5 的低战斗角色战斗值均为 3；加入任何高战斗角色后队伍战斗值至少为 6，因此无法进入该区间。
- Jackie 已决定保留正式角色与结果条件；当正式角色能力数值无法覆盖某结果区间时，专项测试临时创建普通 `CharacterAsset` 覆盖该结果，该情况按数值覆盖缺口验收，不判定为角色设计缺陷。
- `tests/fixtures/test_injured_rescue_character.tres` 仍作为基础规则回归资产；Task 7 完整专项测试已临时创建战斗 5、调查 5、交涉 0 的普通角色，角色不进入正式运行路径。
- 该口径只解决数值覆盖，不改变正式角色设计与正式 `GameSession` 资产边界；Task 7 完整专项自动与人工验收均已通过。

## Task 7 自动验收结论

- `tests/v3_task7_acceptance_test.tscn` 退出码为 0，四条正式路线均通过 `GameSession`，临时普通角色命中 `result_missing_caravan_injured_rescue`，并验证两日生命周期、到期前结算拒绝、重复占用拒绝、重复结算拒绝、状态效果、报告记录和角色释放。
- 专项测试输出：`formal_routes=4, temporary_numeric_fallback=true, lifecycle=true, persistent_effects=true`；正式主场景、Task 1–6、fixture 与 V2 `runtime_chain` 回归退出码均为 0。
- 专项负例的结算 ERROR 属于预期拒绝分支；Godot 环境告警为 `user://logs/godot.log` 写入失败和根证书仓库读取失败，未发现游戏逻辑错误。

## Task 8 工作状态

Task 8 已完成：接入“塌方矿井”并验证第二张任务结构；结果 ID、终态 ID 与报告文本采用类型加语义的稳定占位符，待正式策划冻结后替换。Jackie 已确认第二张任务人工验收通过。

## Task 8 自动验收结论

- 正式任务 `task_collapsed_mine_rescue` 使用 `TaskAsset → TaskInstance → DispatchInstance → TaskResolutionSystem → ResultAsset → ResultInstance → ResultSettlementSystem → ReportIntelSystem` 现有链路；未新增通用规则引擎或隐式优先级。
- 工作阈值为战斗 ≥7、调查 ≥6、交涉 ≥8；8 个结果分别覆盖调查、交涉、战斗单项，调查加战斗、调查加交涉、交涉加战斗，三项均不足和三项全部满足。
- `tests/v3_task8_collapsed_mine_test.tscn` 退出码为 0，输出 `results=8, formal_routes=8, unique_results=true, game_session=true`；Task 1–7、V2 `runtime_chain`、首张主场景和第二张 UI 场景启动均通过。
- `GameSession.task_asset_path` 的默认值仍指向首张任务，第二张 UI 通过场景属性选择正式任务，正式角色池和状态拥有者保持同一套实现。
- 任务承诺报酬 120、报告文本与任务终态仍属于工作性占位内容；正式策划冻结前不视为最终数值或文案。

## 历史归档

旧版重复发现记录已移至用户输出归档 `C:\Users\lvy\Documents\Codex\2026-08-29\shi\outputs\context_archive_2026-08-30\findings_legacy.md`，需要追溯时再查阅。

## Demo Readiness 深度审计（2026-08-31）

### 实际结构图

`assets/types（Resource 契约） → assets/data（6 角色、2 任务、2 结果组、13 结果） → runtime（Guild / Task / Dispatch / Resolution / Settlement / Report / Day） → ui（正式主界面与四类面板） → tests（12 个 headless 场景与 TEST_ONLY fixtures）`。

仓库当前共 47 个 GDScript、19 个场景和 34 个 `.tres` 资源；`addons/` 未安装第三方测试插件，`runtime/save/` 不存在。

### 本轮已实施

- `runtime/tasks/task_system.gd`：最终结果只允许写入 `IN_PROGRESS` 任务，拒绝覆盖结果；终态要求已有最终结果；增加失败预检用的结果清理入口。
- `runtime/dispatch/dispatch_system.gd`：定时派遣只能在到期日结束，增加结束预检，空角色引用不会触发占用扫描异常。
- `runtime/tasks/task_resolution_system.gd`：只接受 `ACTIVE` 派遣；整体校验结果组 ID、条件类型、能力引用和非负能力值，拒绝空条件、重复结果和未知能力。
- `runtime/results/result_settlement_system.gd`：结算必须携带匹配的权威 `ResultAsset`，逐项拒绝篡改效果；核对 Result/Dispatch/Task 关联、派遣状态、任务生命周期与最终结果；拒绝空效果、同批次情报冲突和多个终态，并保存事务快照供后续失败回滚，成功结束后显式提交并释放快照。
- `runtime/game_session.gd`：正式任务路径限制在规范化 `assets/data/tasks/`，加载时校验正式任务、结果组、条件、效果（每个结果恰好一个终态）和六名角色；结算前预检派遣结束条件，报告先行记录，后续失败时清理报告、任务和状态快照。
- `ui/reports/report_view.gd`、`ui/main/guild_main.gd`：异常报告引用不会把工作区留在隐藏状态。
- `tests/runtime_chain_test.gd`、`tests/vertical_slice_test.gd`：测试脚本改为汇总失败并返回真实退出码；新增 `tests/demo_readiness_audit_test.tscn`，覆盖角色/任务加载、引用完整性、非法字段、派遣、结果判定、权威效果、防篡改、冲突情报、终态数量、结算、异常数据、生命周期和内存恢复边界。
- 文档真源：架构与流程文档统一使用 `report_text`、`battle`，测试描述改为 Godot headless 场景脚本测试。

### 已发现但暂未处理

- `SaveSystem`：**NOT IMPLEMENTED**。仓库没有磁盘存档脚本；本轮只验证 `GuildState.restore_value()` 的内存恢复入口。
- 伤势、关系、情报尚未被后续任务判定消费：**NOT IMPLEMENTED**。当前只记录和查询运行时状态。
- `EventAsset`、JSON/Excel Importer、正式 Runtime Schema 和标准任务终态枚举：**NOT IMPLEMENTED / UNVERIFIED**。
- Task8 的 `promised_reward = 120` 尚未映射为结果效果，八份报告和终态仍为策划占位符：**UNVERIFIED**，未擅自补数值。
- UI 自动测试仍通过信号触发，真实鼠标、焦点、禁用控件和窗口布局需要人工验收：**UNVERIFIED**。
- `TaskAsset.repeatable` 仍未在低层 `TaskSystem` 执行，重复发布策略需 V4 冻结：**UNVERIFIED**。
- 低层 `TaskSystem.record_final_result()` 已核对结果 ID 必须属于创建任务的 `result_group`；不完整 `TaskAsset` 的通用 schema 仍由正式 `GameSession` 校验，低层统一校验留待 V4。

### 二次审查关注点

- 当前结算入口已强制保持 Result/Dispatch/Task 三者关联，并在正式路径使用权威 `ResultAsset`；后续新增入口需复用同一校验。
- 引入存档前仍需冻结终态、序列号、报告阅读和结算去重字段。
- 正式文案和奖励冻结后，补充 Task8 八路线的金币与报告断言。

### 最终验证记录

- 47 个 GDScript 单文件检查通过；12 个 headless 测试场景全部退出码 0；`guild_main.tscn` 与 `collapsed_mine_guild_main.tscn` 启动退出码 0。
- 正式 `assets/data` 共 23 个 `.tres`，静态 ID 重复数为 0；场景和资源的现有引用未发现缺失。
- Godot 仍输出 `user://logs/godot.log` 写入失败、根证书仓库读取失败等环境告警；这些告警不计入业务失败，人工场景零 ERROR 仍标记 **UNVERIFIED**。
