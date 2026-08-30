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
- 本地 Notion 快照属于“测试用 v1”；未冻结字段继续标记 `【占位占位】`。

## Task 3 阻塞证据

- 完整成功：90 金币、商人评价上升已确认；评价数值、状态 ID、任务终态、完整报告未定。
- 延迟成功：幸存者获救、伤势恶化、部分货物转移、部分报酬、治疗/追赃方向已确认；金额未定。
- 带伤救回：实际参与角色受伤、伤势在结算时确定已确认；受伤目标规则和等级未定。
- 查明位置：位置与幸存者状态情报已确认；任务终态和后续稳定资产引用未定，快照明确“无稳定资产引用”。
- 搜索失败：任务失败、商人信任下降已确认；信任数值、状态 ID、完整报告未定。

## 占位与推测

### `【占位占位】`

- 五个结果终态、延迟奖励、评价/信任数值、状态 ID 与拥有者、伤势目标/等级、后续救援稳定 ID、五份完整报告文本。
- 正式角色数量、结果组状态文案、情报/关系状态最终归属。

### 工作性推测，均未视为正式策划

- 延迟奖励：60 金币。
- 完整成功评价：`+5`。
- 搜索失败信任：`-5`。
- 受伤目标：实际参与队伍中战斗能力最高的角色。
- 伤势等级：1。
- 查明位置：当前任务部分完成，并保留救援 ID `【占位占位】`。

## 下一步

等待 Jackie 确认以上策划与架构缺口；收到确认后执行 Task 3，并完成单脚本检查、专项测试、受影响回归、旧引用搜索和差异审计。

## 历史归档

旧版重复发现记录已移至用户输出归档 `C:\Users\lvy\Documents\Codex\2026-08-29\shi\outputs\context_archive_2026-08-30\findings_legacy.md`，需要追溯时再查阅。
