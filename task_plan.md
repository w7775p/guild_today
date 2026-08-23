# 《今日公会照常营业》运行时垂直切片计划 V2

## 计划意图

基于 `D:\Godot\guild_today` 当前文件、DOC-1～DOC-5 重构结果和冻结架构，重新排列 Task 0–16，使每个 Task 只引入一个可验证能力，并最终跑通：

`TaskAsset → TaskInstance → DispatchInstance → TaskResolutionSystem → ResultGroupAsset → ResultAsset → ResultInstance → ResultSettlementSystem → GuildState → ReportIntelSystem`

## 当前状态

- 唯一项目目录：`D:\Godot\guild_today`。
- 当前执行任务：无。
- Task 0：已完成。
- Task 1：已完成目录校准与重新验收。
- Task 2：已完成目录校准与重新验收。
- Task 3：已完成最小 ConditionResource 与 AbilityCondition 验收。
- Task 4：已完成最小 EffectResource、GoldEffect 与 ReputationEffect 验收。
- Task 5：已完成 ResultAsset 验收。
- Task 6：已完成 ResultGroupAsset 与互补结果分支验收。
- Task 7：已完成 TaskInstance 与运行事实隔离验收。
- Task 8：已完成 DispatchInstance 与派遣成员唯一真源验收。
- Task 9–16：Jackie 已授权按 V2 顺序逐项执行，尚未开始。
- DOC-1～DOC-5：已完成，历史保存在 `progress.md` 与 `findings.md`，不再混入功能 Task 清单。
- Task 1–8 均已形成可回退的本地提交检查点；尚未 push。

## 状态标记

- `[ ] 待授权`：尚未获得执行许可。
- `[~] 待校准验收`：核心能力已验证，但当前实现不满足最新架构或目录契约。
- `[+] 已授权待执行`：Jackie 已授权，尚未开工。
- `[>] 执行中`：正在执行当前唯一 Task。
- `[x] 已完成`：满足本 Task 全部验收条件并有 Godot 实际运行证据。

## 执行闸门

- 本文件是计划，不自动授予执行权限；只有 Jackie 明确说“执行 Task X”后才能执行。
- 每次只执行一个 Task，不顺手实现后续能力。
- 所有新增或修改代码必须带简明中文注释。
- 静态检查、空壳类和文件存在均不能算完成；每个 Task 必须通过 Godot 4.7.2 实际加载或运行验收。
- TEST_ONLY fixture 统一放在 `tests/fixtures/`，ID 使用 `test_` 前缀，不得反向冻结正式策划 Schema。
- 禁止擅自创建通用 RuleEngine、Condition/Effect DSL、万能执行器、EventBus、ServiceLocator 或未冻结目录。
- 未获 Jackie 明确授权，禁止 git commit、git push、合并、强推或删除分支。
- 完成后固定报告：做了什么、没做什么、验证结果、下一步建议。

## V1 → V2 编号调整

| V1 能力 | V2 Task | 调整原因 |
|---|---:|---|
| Task 0 项目入口 | 0 | 保持不变 |
| Task 1 CharacterAsset | 1 | 增加 `assets/types/` 目录校准 |
| Task 2 TaskAsset | 2 | 增加 `assets/types/` 目录校准 |
| Task 10 Condition | 3 | 提前，解除 ResultAsset 强类型依赖倒置 |
| Task 12 Effect | 4 | 提前，解除 ResultAsset 强类型依赖倒置 |
| Task 3 ResultAsset | 5 | 等待 Condition/Effect 最小类型存在 |
| Task 4 ResultGroupAsset | 6 | 等待 ResultAsset 存在 |
| Task 5–9 Runtime 与创建系统 | 7–11 | 按冻结目录与数据流重排 |
| Task 11 Resolution | 12 | 等待 ResultGroup、Condition、Dispatch 全部存在 |
| Task 13–14 Guild/Settlement | 13–14 | 保持结算依赖顺序 |
| Task 15 ReportSystem | 15 | 对齐为 `ReportIntelSystem` 薄边界 |
| Task 16 Vertical Slice | 16 | 补全 ResultGroupAsset 与 ResultAsset 链路 |

## Task 清单

### [x] Task 0：确认项目与文档基线

- 单一目标：确认唯一仓库是可实际启动、可按规则协作的 Godot 项目。
- 范围：`project.godot`、主场景、启动脚本、根 `AGENTS.md`、`docs/project/`。
- 验收：Godot 4.7.2 成功加载并运行主场景，输出 `Guild Today Open As Usual boot success`；文档入口与链接检查通过。
- 已有证据：Godot 编辑器加载成功，无界面运行退出码为 0；DOC-1～DOC-5 已完成。
- 不包含：任何业务 Resource、Runtime 或 System 能力。

### [x] Task 1：校准 CharacterAsset

- 单一目标：让已验收的 CharacterAsset 落到冻结目录并保持原能力不变。
- 实现：将脚本收敛到 `assets/types/character_asset.gd`，同步更新 `.uid` 与 `tests/fixtures/character_a.tres` 引用。
- 字段：`id`、`name`、`battle`、`investigation`、`negotiation`。
- 验收：Godot 4.7.2 从新路径加载 `character_a.tres`，读出“角色A”和 `investigation = 10`；全局无旧 `res://resources/character/` 引用。
- 验收证据：Godot 4.7.2 单脚本检查与主场景运行退出码均为 0；新路径 fixture 读出“角色A”和 `investigation = 10`；旧资源路径无代码或资源引用。
- 不包含：扩展角色 Schema、角色运行状态、派遣或任务判定。

### [x] Task 2：校准 TaskAsset

- 单一目标：让已验收的 TaskAsset 落到冻结目录并保持原能力不变。
- 实现：将脚本收敛到 `assets/types/task_asset.gd`，同步更新 `.uid` 与 `tests/fixtures/abandoned_hospital.tres` 引用。
- 字段：`id`、`title`、`description`、`repeatable`、`result_group`、`event_reference`。
- 当前边界：`result_group` 在 Task 6 前允许保持最小 Resource 引用；`event_reference` 保持空引用，不提前实现 EventAsset。
- 验收：Godot 4.7.2 从新路径加载任务 fixture 并读出正确字段；全局无旧 `res://resources/task/` 引用。
- 验收证据：Godot 4.7.2 单脚本检查与主场景运行退出码均为 0；新路径 fixture 读出废弃医院任务的正确字段；旧资源路径无代码或资源引用。
- 不包含：任务实例化、ResultGroup 绑定、事件运行逻辑。

### [x] Task 3：实现最小 ConditionResource

- 单一目标：提供 ResultAsset 可强类型引用的最小条件能力。
- 实现：`assets/types/condition_resource.gd`、`assets/types/ability_condition.gd`。
- 第一条具体规则：`AbilityCondition` 判断一个明确能力值是否达到阈值；只验证 `investigation >= value`。
- 验收：Godot 实际运行中，能力值 12 对阈值 10 返回 `true`，对阈值 13 返回 `false`；Resource 可保存并加载。
- 验收证据：Godot 4.7.2 对两个类型脚本与验收脚本的单脚本检查均为 0；两个 TEST_ONLY Resource 实际加载成功，并输出 `investigation=12, threshold_10=true, threshold_13=false`。
- 不包含：Dispatch 聚合、ResultGroup 遍历、OR/NOT、ConditionGroup、通用规则引擎或 DSL。

### [x] Task 4：实现最小 EffectResource

- 单一目标：提供 ResultAsset 可强类型引用的最小效果数据。
- 实现：`assets/types/effect_resource.gd`、`assets/types/gold_effect.gd`、`assets/types/reputation_effect.gd`。
- 字段：具体效果只保存确定性的 `amount`；Effect 不直接写入任何状态。
- 验收：Godot 可保存并加载 `gold +100` 与 `reputation +5` 两个 TEST_ONLY 效果资源，并读出正确类型和值。
- 验收证据：Godot 4.7.2 对三个类型脚本与验收脚本的单脚本检查均为 0；两个 TEST_ONLY Resource 实际加载成功，并输出 `gold=100, reputation=5`。
- 不包含：GuildState、效果执行、结算编排、通用 EffectExecutor 或 DSL。

### [x] Task 5：创建 ResultAsset

- 单一目标：定义一个具体任务结果的静态配置。
- 实现：`assets/types/result_asset.gd`。
- 字段：`id`、`conditions: Array[ConditionResource]`、`effects: Array[EffectResource]`、`report_text`。
- 当前边界：`report_text` 只服务首轮 TEST_ONLY 闭环，不冻结完整报告资产 Schema。
- 验收：Godot 可保存并加载一个成功结果，正确读出条件、金币效果、声望效果和报告文本引用内容。
- 验收证据：Godot 4.7.2 对 ResultAsset 与验收脚本的单脚本检查均为 0；成功结果 Resource 实际加载一项 AbilityCondition、两项 EffectResource 与报告文本“废弃医院调查完成”。
- 不包含：条件判断、效果执行、结果选择。

### [x] Task 6：创建 ResultGroupAsset

- 单一目标：让一个任务引用一组互斥结果。
- 实现：`assets/types/result_group_asset.gd`，并把 `TaskAsset.result_group` 收紧为明确的 ResultGroupAsset 引用；补充 `AbilityBelowCondition` 形成互补失败条件。
- 字段：`id`、`results: Array[ResultAsset]`。
- 测试数据：成功与失败两个 ResultAsset，以及一个废弃医院 ResultGroup。
- 验收：Godot 加载任务 fixture 后，可沿 `TaskAsset → ResultGroupAsset → ResultAsset[]` 读出成功、失败两个结果。
- 验收证据：Godot 4.7.2 对 AbilityBelowCondition、ResultGroupAsset、TaskAsset 与验收脚本的单脚本检查均为 0；任务 fixture 实际读出成功、失败两个结果，阈值 10 两侧互斥且完备。
- 已确认方案：成功使用 `investigation >= 10`，失败使用 `investigation < 10`，两者互斥且完备。
- 不包含：优先级、结果选择、条件执行。

### [x] Task 7：实现 TaskInstance

- 单一目标：表达“某个 TaskAsset 在本局实际发生了一次”。
- 实现：`runtime/tasks/task_instance.gd`，类型为 `RefCounted`。
- 字段：`instance_id`、`task_id`、`lifecycle_state`、`final_result_id`、`runtime_progress`。
- 验收：同一任务可手动生成两个不同 `instance_id` 的实例，互不污染运行事实。
- 验收证据：Godot 4.7.2 对 TaskInstance 与验收脚本的单脚本检查均为 0；两个实例引用同一任务，实例 ID 不同，生命周期、最终结果与进度事实保持隔离。
- 不包含：`party_member_ids` 真源、正式生命周期枚举、任务生成系统、派遣与结算。

### [x] Task 8：实现 DispatchInstance

- 单一目标：记录一次派遣决定，并成为派遣成员唯一运行真源。
- 实现：`runtime/dispatch/dispatch_instance.gd`，类型为 `RefCounted`。
- 字段：`dispatch_instance_id`、`task_instance_id`、`character_refs[]`、`status`。
- 当前边界：`started_at / ended_at` 的类型与单位未冻结，本 Task 不猜测实现。
- 验收：三个角色引用可保存并读取；TaskInstance 不保存可变成员副本。
- 验收证据：Godot 4.7.2 对 DispatchInstance 与验收脚本的单脚本检查均为 0；一次派遣实际保存并读回三个 CharacterAsset 引用，TaskInstance 没有 `party_member_ids`。
- 不包含：派遣合法性、角色占用、结果判定。

### [ ] Task 9：实现 ResultInstance

- 单一目标：记录一次已经确定的结果事实。
- 实现：`runtime/results/result_instance.gd`，类型为 `RefCounted`。
- 字段：命中的 `result_asset_id`、对应 `dispatch_instance_id`、本次确定的 `resolved_effects`。
- 验收：实例可保存并读取结果 ID、派遣 ID 与两个已确定效果引用，且不修改 ResultAsset。
- 不包含：结果选择、效果执行、报告生成、未冻结的完整结算记录 Schema。

### [ ] Task 10：实现 TaskSystem

- 单一目标：由 TaskAsset 创建并拥有 TaskInstance 运行事实。
- 实现：`runtime/tasks/task_system.gd`。
- 最小职责：生成唯一实例 ID、保存实例、通过公开 API 记录 `final_result_id`。
- 验收：系统从废弃医院 TaskAsset 创建两个独立 TaskInstance，并能给指定实例记录最终结果 ID。
- 不包含：每日刷新、生成条件框架、派遣、结果选择、完整生命周期枚举。

### [ ] Task 11：实现 DispatchSystem

- 单一目标：创建、保存和结束合法 DispatchInstance。
- 实现：`runtime/dispatch/dispatch_system.gd`。
- 最小职责：创建派遣、维护 ACTIVE/ENDED、从 ACTIVE Dispatch 推导角色占用。
- 验收：同一角色不能同时进入第二个 ACTIVE 派遣；结束第一次派遣后可再次派遣。
- 不包含：独立 `is_busy` 副本、时间系统、任务结果判定。

### [ ] Task 12：实现 TaskResolutionSystem

- 单一目标：根据 DispatchInstance 在 ResultGroup 中唯一选择 ResultAsset。
- 实现：`runtime/tasks/task_resolution_system.gd`。
- 流程：读取派遣角色 → 汇总三项能力 → 检查 ResultAsset 条件 → 要求唯一命中 → 返回 `result_id`。
- 验收：调查能力满足阈值时选择成功结果，不满足时选择失败结果；零命中或多命中明确报错。
- 不包含：效果执行、GuildState 修改、报告生成、优先级排序。

### [ ] Task 13：实现 GuildState 与 StateValue

- 单一目标：通过稳定 state_id 保存和修改公会金币与总声望。
- 实现：`runtime/guild/state_value.gd`、`runtime/guild/guild_state.gd`。
- 最小状态：Gold、TotalReputation；外部只能通过 GuildState 公开 API 读写。
- 验收：金币从 0 增加到 100、总声望从 0 增加到 5，并能按稳定 state_id 正确读取。
- 不包含：库存、设施、债务、评级、地区声望或存档。

### [ ] Task 14：实现 ResultSettlementSystem

- 单一目标：把 ResultInstance 中已确定效果分发到其状态拥有者。
- 实现：`runtime/results/result_settlement_system.gd`。
- 首轮范围：GoldEffect 与 ReputationEffect 只能通过 GuildState API 生效。
- 验收：结算成功结果后，金币为 100、总声望为 5；重复结算必须被阻止或明确失败。
- 不包含：结果选择、角色状态、关系状态、报告排版、通用效果执行器。

### [ ] Task 15：实现 ReportIntelSystem 薄边界

- 单一目标：把已确定结果与已结算效果转换为玩家可读报告。
- 实现：`runtime/reports/report_intel_system.gd`。
- 验收：确定性输出“废弃医院调查完成”“获得金币100”“声望提升5”等内容。
- 不包含：独立 ReportAsset、UI、富文本、历史报告数据库或情报扩展系统。

### [ ] Task 16：完整 Vertical Slice 自动验收

- 单一目标：只组装 Task 0–15 已有能力，证明第一条运行链真实闭环。
- 固定输入：角色 A，`investigation = 12`；废弃医院任务；成功效果 `gold +100`、`reputation +5`。
- 完整链：`TaskAsset → TaskInstance → DispatchInstance → TaskResolutionSystem → ResultGroupAsset → ResultAsset → ResultInstance → ResultSettlementSystem → GuildState → ReportIntelSystem`。
- 验收：Godot 4.7.2 实际运行退出码为 0；唯一命中成功结果；最终金币 100、总声望 5；输出确定报告；无解析错误、断言失败或运行时错误。
- 不包含：完整 UI、编辑器工具、Importer、存档、随机、事件链或未冻结扩展。

## 依赖顺序

`0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16`

默认严格按顺序执行。若要跳过依赖，必须由 Jackie 明确批准，并在 `findings.md` 记录原因与风险。

## 单 Task 完成报告

### 这次做了什么

- 只列当前 Task 实际完成内容。

### 这次没做什么

- 明确列出刻意未触碰的后续能力。

### 验证结果

- 写明 Godot 版本、执行方式、预期、实际输出与退出码。

### 下一步建议

- 只建议一个最靠前的未完成 Task，不自动执行。

## 当前下一步

下一次只执行 Task 9 的 ResultInstance。
