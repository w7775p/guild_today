# 当前关键发现

## 当前决策

- Resource 只保存静态定义；Runtime/Instance 保存已发生事实；System 管理运行逻辑。
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
- Task 5 正常专项日志零 ERROR；Task 3/4 与 V2 `runtime_chain` 回归通过。

## Task 6 验证结论

- 核心循环 UI 只通过 `GameSession` 查询状态和提交命令，没有直接写入 Task、Dispatch、Guild、Character 或 Report 字段。
- `GameSession.validate_dispatch()` 提供玩家可见失败原因；界面确认按钮仅在 1–2 名合法角色时启用。
- 报告进入独占阅读态，展示结果 ID、派遣队伍最高能力和已结算后果；关闭只修改报告阅读状态。
- Task 6 专项、正式主场景启动、Task 5 与 V2 `runtime_chain` 回归均通过，正常日志零 ERROR。

## 下一步

等待 Jackie 授权 V3 Task 7；占位策划内容继续按本文件的唯一语义占位符映射维护。

## 历史归档

旧版重复发现记录已移至用户输出归档 `C:\Users\lvy\Documents\Codex\2026-08-29\shi\outputs\context_archive_2026-08-30\findings_legacy.md`，需要追溯时再查阅。
