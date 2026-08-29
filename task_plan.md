# 《今日公会照常营业》V3 可玩游戏循环执行计划

## 1. 计划定位

V2 Task 0–16 已完成，证明 TEST_ONLY 运行时骨架能够跑通：

`TaskAsset → TaskInstance → DispatchInstance → TaskResolutionSystem → ResultGroupAsset → ResultAsset → ResultInstance → ResultSettlementSystem → GuildState → ReportIntelSystem`

V3 的目标是把测试骨架推进为一段可实际操作、可人工判断、可产生持续后果的真实游戏循环：

`阅读真实委托与角色 → 选择队伍 → 确认派遣 → 等待两日 → 唯一结果判定 → 结算持续后果 → 阅读报告 → 后果影响下一次选择`

V3 只使用已经存在的真实策划资产验证产品，不继续扩充角色数量与任务数量。

## 2. 当前事实

- 唯一项目目录：`D:\Godot\guild_today`。
- 禁止操作：`D:\Godot\guild-workbench`。
- V2 Task 0–16：已完成并已推送。
- 当前执行任务：无。
- V3 有效编号：Task 1–8，共 8 个 Task。
- V3 Task 1–8 当前均未授权执行。
- 第一张正式任务：`task_missing_caravan`，显示名“失踪商队调查”。
- 第一批正式角色：
  - `hero_aelius`
  - `hero_rin`
  - `hero_dai`
  - `hero_patrick`
  - `hero_astrid`
  - `hero_viletta`
- 第一张正式结果组：`result_group_missing_caravan`，包含 5 个结果。
- 第二张结构反例：`task_collapsed_mine_rescue`，显示名“塌方矿井”。
- 当前 `project.godot` 主场景仍是测试场景；正式 `GameSession` 与核心循环 UI 尚未建立。
- 当前 `TaskResolutionSystem` 使用队伍能力求和；真实任务要求读取队伍最高战斗、最高调查和最高交涉。

## 3. 策划与工程真源

### 3.1 Notion 策划入口

- 当前项目真源：`https://app.notion.com/p/3bb7fb71ada4814888f9ea8e28e501d4`
- 当前角色池：`https://app.notion.com/p/3c87fb71ada48046859dd6319bf6d491`
- 当前任务池：`https://app.notion.com/p/3cb7fb71ada480809a6ec11c2a5e10b2`
- 当前结果组池：`https://app.notion.com/p/3cb7fb71ada4812e96c7ee9a3672827f`
- Demo 美术资产清单：`https://app.notion.com/p/3cb7fb71ada481bd8e3aeb2ababdef26`

### 3.2 本地工程入口

每次开工必须完整读取：

1. `AGENTS.md`
2. `docs/project/workflow.md`
3. `docs/project/architecture.md`
4. `docs/project/engineering_rules.md`
5. `docs/project/known_traps.md`
6. `task_plan.md`
7. `progress.md`
8. `findings.md`
9. 当前 Task 直接涉及的代码、测试与资产

策划内容冲突时，Jackie 最新明确决定优先；Notion 对应当前页面其次。本地代码只能证明现状，不能覆盖策划与冻结架构。

## 4. 新对话接力协议

新对话中的 Agent 必须执行以下顺序：

1. 完整读取第 3.2 节列出的本地文件。
2. 检查 `git status --short --branch`，识别 Jackie 已有改动。
3. 从本文件确认 Jackie 指定的 V3 Task。
4. 只把该 Task 标为 `[>] 执行中`。
5. 只实现该 Task 的单一目标。
6. 完成对应单脚本检查、相关 Godot 测试、旧引用搜索与 `git diff` 审计。
7. 验收通过后更新 `task_plan.md`、`progress.md`、`findings.md`。
8. 为该 Task 自动创建一次本地完成提交。
9. 停止；等待 Jackie 明确授权下一个 Task。

若 Jackie 只说“继续”，执行最靠前的 `[+] 已授权待执行` Task；若没有已授权 Task，停下询问。

## 5. 状态标记

- `[ ] 待授权`：尚未获得执行许可。
- `[+] 已授权待执行`：Jackie 已授权，尚未开工。
- `[>] 执行中`：当前唯一执行 Task。
- `[!] 阻塞`：存在必须由 Jackie 决定的策划或架构问题。
- `[x] 已完成`：满足全部 Godot 4.7.2 验收条件，并已有本地完成提交。

## 6. V3 通用执行闸门

### 6.1 一次只做一件事

- 每次只执行一个 Task。
- 当前 Task 验收完成后停止。
- 禁止顺手实现下一 Task。
- 后续 Task 所需文件可以在计划中列出，但当前 Task 不得提前创建。

### 6.2 决策阻塞

遇到以下情况必须停止并询问 Jackie：

- 真实策划内容缺少精确数值、稳定 ID、任务终态或报告文本。
- 同一内容在角色池、任务池、结果组池之间冲突。
- 实现需要新增计划外的状态系统、规则类型或目录。
- 一个结果出现零命中、多命中或持续后果没有明确拥有者。
- 需要改变玩家可见规则或任务设计。

禁止凭经验补值、用默认值掩盖缺口、把“待定”翻译成程序规则。

### 6.3 工程边界

- 所有新增或修改代码必须带简明中文注释。
- Resource 只保存静态定义，运行时不得写回。
- 派遣成员只以 `DispatchInstance.character_refs[]` 为运行真源。
- UI 只读取状态和提交命令。
- API 负责命令，Signal 只通知已发生事实。
- 禁止新增通用 `RuleEngine`、DSL、万能执行器、`EventBus`、`ServiceLocator`。
- 禁止提前实现完整 Importer、编辑器、存档、设施、库存、天气、小时制日历。
- V3 判定保持确定性，不引入随机。
- 正常人工验收场景必须零 ERROR；预期失败分支放入独立自动测试，避免污染人工验收控制台。

### 6.4 每个 Task 的固定验证

1. 对新增或修改的每个 `.gd` 执行 Godot 4.7.2 单脚本 `--check-only --script`。
2. 运行当前 Task 的专项测试。
3. 运行受影响的既有 V2 回归测试。
4. 搜索旧 ID、旧方法、旧路径与已删除字段。
5. 执行 `git diff --check`。
6. 审计 `git diff --stat` 与 `git diff`，确认没有无关改动。
7. 确认 `.godot/` 未进入提交，必要的 `.uid` 已纳入提交。

### 6.5 Git 规则

- Jackie 授权执行某个 V3 Task，即同时授权该 Task 验收通过后创建一次本地完成提交。
- 一个 Task 只允许一个完成提交。
- 失败、阻塞或验收未完成时禁止提交。
- 提交范围只包含当前 Task 与三份规划记录的必要更新。
- 禁止自动 push；push 永远等待 Jackie 明确授权。
- 禁止合并、强推、删除分支或改写历史。

## 7. V3 Task 清单

### [ ] V3 Task 1：建立首轮正式内容资产

#### 单一目标

让六名正式角色、“失踪商队调查”、结果组及五个结果以正式 Godot Resource 形式加载，并形成可追踪的稳定引用链。

#### 开工输入

- 当前角色池中的六张正式角色卡。
- 当前任务池中的“失踪商队调查”。
- 当前结果组池中的 `result_group_missing_caravan`。
- 现有 `CharacterAsset`、`TaskAsset`、`ResultGroupAsset`、`ResultAsset`、`ConditionResource`、`EffectResource`。

#### 开工前策划闸门

必须确认以下缺口已有明确答案；任何一项仍待定时，将本 Task 标为 `[!]` 并询问 Jackie：

1. 五个结果对应的任务终态。
2. “延迟成功”的具体金币报酬。
3. “完整成功”和“搜索失败”的商会信任或声望变化数值及状态归属。
4. “带伤救回”的受伤角色选择规则与伤势等级。
5. “查明位置”是否完成当前任务，以及后续救援使用的稳定任务或解锁 ID。
6. 五个结果最终展示给玩家的完整报告文本。
7. Notion 当前项目真源的角色数量与当前角色池六人记录冲突如何处理。
8. 当前任务池中“结果组待建立”旧文案是否按现有结果组引用校准。

#### 允许修改

- `assets/types/character_asset.gd`
- `assets/types/task_asset.gd`
- `assets/types/result_asset.gd`
- `assets/types/result_group_asset.gd`
- 当前内容实际需要的最小 Condition / Effect 静态字段
- `assets/data/characters/`
- `assets/data/tasks/`
- `assets/data/results/`
- Task 1 专项测试
- 三份规划记录

#### 最小字段工作集

CharacterAsset 只允许加入首张任务判定和首轮 UI 明确需要的字段：

- `id`
- `name`
- `profession`
- `battle`
- `investigation`
- `negotiation`

TaskAsset 只允许加入首张任务展示、派遣和等待明确需要的字段：

- `id`
- `title`
- `commissioner`
- `description`
- `objective`
- `promised_reward`
- `duration_days`
- `min_party_size`
- `max_party_size`
- `repeatable`
- `result_group`

玩家可见风险、推荐能力和公开情报若无法由现有文本字段表达，先确认 UI 的实际消费方式，再增加最小字段。禁止复制整张策划卡的全部字段。

#### 实施步骤

1. 建立“策划字段 → Godot 字段 → 消费方”映射。
2. 处理第一个任务的策划缺口。
3. 扩展最小 Resource 类型。
4. 在 `assets/data/characters/` 创建六名正式角色资源。
5. 在 `assets/data/tasks/` 创建 `task_missing_caravan.tres`。
6. 在 `assets/data/results/` 创建一个结果组与五个结果资源。
7. 校验 `TaskAsset → ResultGroupAsset → ResultAsset[]` 的全部稳定引用。
8. 保留 V2 TEST_ONLY fixture，证明正式数据与测试数据可以并存。

#### 验收

- Godot 4.7.2 实际加载六名正式角色，三项能力值与策划卡一致。
- 实际加载 `task_missing_caravan`，正确读出委托人、目标、90 金币、两日、1–2 人。
- 沿任务引用读取 `result_group_missing_caravan` 和五个稳定结果 ID。
- 正式资源均位于 `assets/data/`，ID 无 `test_` 前缀。
- TEST_ONLY 资源仍只位于 `tests/fixtures/`。
- 本 Task 不执行结果判定。

#### 不包含

- 最高能力计算。
- 五结果唯一选择。
- 伤势、关系、情报运行状态。
- 时间推进。
- GameSession。
- UI。
- JSON Importer。

#### 完成提交

`feat(v3): 建立首轮正式内容资产`

---

### [ ] V3 Task 2：实现真实队伍能力判定

#### 单一目标

让 `TaskResolutionSystem` 按“失踪商队调查”的真实规则读取队伍最高能力，并在五个结果中唯一命中。

#### 前置条件

- V3 Task 1 已完成。
- 五个结果条件已经能由调查与战斗能力明确表达。

#### 当前差距

- V2 使用三项能力求和。
- 当前 Condition 接口只接收一个调查整数。
- 真实任务分别读取队伍最高调查与最高战斗。
- 真实任务包含能力区间和两阶段组合。

#### 允许修改

- `assets/types/condition_resource.gd`
- `assets/types/ability_condition.gd`
- `assets/types/ability_below_condition.gd`
- `runtime/tasks/task_resolution_system.gd`
- 首张任务的五个 ResultAsset 条件资源
- Task 2 专项测试
- 受影响的 V2 fixture 与测试
- 三份规划记录

#### 实现边界

1. `TaskResolutionSystem` 从 `DispatchInstance.character_refs[]` 即时计算：
   - 最高战斗
   - 最高调查
   - 最高交涉
2. `AbilityCondition` 增加稳定 `ability_id`，表达“指定能力达到阈值”。
3. `AbilityBelowCondition` 增加稳定 `ability_id`，表达“指定能力低于阈值”。
4. 区间通过多个明确条件的 AND 组合表达。
5. 禁止创建通用比较运算 DSL、表达式解析器或优先级系统。

#### 五结果目标规则

- 搜索失败：最高调查 < 5。
- 完整成功：最高调查 ≥ 7 且最高战斗 ≥ 6。
- 延迟成功：最高调查 5–6 且最高战斗 ≥ 6。
- 带伤救回：最高调查 ≥ 5 且最高战斗 4–5。
- 查明位置：最高调查 ≥ 5 且最高战斗 < 4。

最终规则以 Jackie 对 Task 1 策划闸门的确认结果为准。

#### 测试矩阵

至少覆盖当前任务卡中的下列派遣：

- 维蕾塔单人。
- 阿斯特里德单人。
- 埃利乌斯单人。
- 凛单人。
- 戴禛单人。
- 帕特里克单人。
- 维蕾塔＋一名战斗角色。
- 戴禛或帕特里克＋埃利乌斯或凛。
- 戴禛＋帕特里克。
- 埃利乌斯＋凛。

#### 验收

- 每组派遣只命中一个预期结果。
- 零命中与多命中在独立自动测试中明确失败。
- 正常人工场景不主动触发预期错误分支。
- 组队能力采用最高值，未保存合计值或最高值副本。
- V2 既有成功/失败 fixture 经校准后继续通过。

#### 不包含

- 结果效果执行。
- 状态持久化。
- 时间推进。
- UI。
- 特殊职业、角色行为、OR 组或随机。

#### 完成提交

`feat(v3): 支持真实队伍能力判定`

---

### [ ] V3 Task 3：持久化首张任务的结果后果

#### 单一目标

让五个结果的已确认后果写入各自运行状态，并让报告系统保存玩家可读取的结果记录。

#### 前置条件

- V3 Task 2 已完成。
- Task 1 的所有结果效果数值、目标和状态归属已经确认。

#### 状态所有权

- 金币与总声望：`GuildState`。
- 角色伤势：本 Task 新增的最小角色运行状态拥有者。
- 商会信任或关系：`StateRelationshipSystem`。
- 已获得情报与后续内容解锁：`ReportIntelSystem` 或经架构确认的最小拥有者。
- 已发生结果：`ResultInstance`。
- 报告记录：`ReportIntelSystem`。

若真实效果无法落入以上所有者，停止并进行架构决策，禁止临时塞入 `Dictionary`、TaskInstance 或 UI。

#### 允许修改

- 当前结果实际需要的具体 EffectResource。
- `runtime/results/result_settlement_system.gd`
- `runtime/characters/` 下最小角色运行状态类型与系统。
- `runtime/characters/state_relationship_system.gd`
- `runtime/reports/report_intel_system.gd`
- 首张任务五个结果资源。
- Task 3 专项测试。
- 三份规划记录。

#### 实施原则

1. Effect 只描述已确认的静态变化。
2. ResultSettlementSystem 先验证全部效果，再请求各状态拥有者写入。
3. 任一效果无法执行时，整次结算不得产生半写入。
4. 同一 DispatchInstance 继续只允许结算一次。
5. 角色伤势写入运行状态，禁止改写 CharacterAsset。
6. 报告记录至少关联 `result_asset_id`、`dispatch_instance_id` 与确定文本。
7. 报告说明“发生了什么、为什么发生、产生什么后果”，避免只列数字。

#### 验收

- 五个结果均可生成 ResultInstance 并完成一次结算。
- 完整成功正确增加确定金币与已确认声望/信任。
- 延迟成功使用已确认的部分报酬。
- 带伤救回只修改明确目标角色的运行伤势。
- 查明位置写入已确认情报或后续解锁。
- 搜索失败写入已确认关系或声望后果。
- 重复结算被拒绝，任何状态不二次变化。
- 报告可由 ReportIntelSystem 按派遣记录读取。

#### 不包含

- 通用状态机。
- 疲劳、死亡、恢复、状态叠加规则。
- 完整关系网。
- 事件系统。
- 时间推进。
- UI 排版。

#### 完成提交

`feat(v3): 持久化首张任务结果后果`

---

### [ ] V3 Task 4：实现最小日期与任务生命周期

#### 单一目标

让两日任务真实经历“派遣中 → 到期 → 可结算 → 结束”，并在完成前持续占用角色。

#### 前置条件

- V3 Task 3 已完成。
- Jackie 接受 V3 的最小时间单位为“整数游戏日”。

#### 架构冻结

本 Task 允许正式引入最小日期拥有者，建议路径：

- `runtime/time/day_system.gd`

最小职责：

- 保存 `current_day`。
- 提供 `advance_day()`。
- 通知日期已经变化。

派遣时间事实由 DispatchInstance 保存：

- `started_day`
- `due_day`
- `ended_day`

`due_day = started_day + duration_days`。任务到期只表示可以进入结算链，日期系统不直接修改任务、派遣、结果或公会状态。

#### 允许修改

- `docs/project/architecture.md`，记录 V3 最小日期边界。
- `runtime/time/day_system.gd`
- `runtime/dispatch/dispatch_instance.gd`
- `runtime/dispatch/dispatch_system.gd`
- 必要的 TaskInstance 生命周期公开 API。
- Task 4 专项测试。
- 三份规划记录。

#### 验收

- 第 1 日派遣两日任务，`due_day` 确定为第 3 日。
- 第 1、2 日角色保持 ACTIVE 占用。
- 到第 3 日时 DispatchSystem 可明确查询该派遣已到期。
- 到期前禁止结算。
- 显式结束派遣后角色释放，`ended_day` 被记录。
- 日期推进不直接执行判定和结算。

#### 不包含

- 小时、分钟、现实日期、月份、季节、天气。
- 每日随机事件。
- 每日任务刷新。
- 自动存档。
- UI。

#### 完成提交

`feat(v3): 实现最小日期与任务生命周期`

---

### [ ] V3 Task 5：组装正式 GameSession

#### 单一目标

用一个正式 GameSession 编排 Task 1–4 已存在的系统，跑通无 UI 的真实“失踪商队调查”会话。

#### 前置条件

- V3 Task 4 已完成。
- 六名角色、一张任务、五个结果和全部运行状态可独立验收。

#### 计划文件

- `runtime/game_session.gd`
- `runtime/game_session.tscn`
- Task 5 正式会话测试

#### GameSession 职责

- 装配并引用各 System。
- 发布首张正式 TaskInstance。
- 向调用方提供正式角色与任务的只读查询。
- 接收派遣请求并调用 TaskSystem 与 DispatchSystem。
- 接收推进日期请求并调用日期系统。
- 查询到期派遣。
- 对到期派遣依次调用：
  1. TaskResolutionSystem
  2. ResultInstance 创建
  3. TaskSystem 记录最终结果
  4. ResultSettlementSystem
  5. ReportIntelSystem
  6. DispatchSystem 显式结束派遣
- 向外通知任务、日期、状态和报告已经变化。

#### 禁止的职责

- GameSession 不直接修改各系统内部状态。
- GameSession 不保存角色占用、金币、日期或结果的第二副本。
- GameSession 不包含 UI 控件引用。
- GameSession 不读取 TEST_ONLY fixture。
- GameSession 不作为 Autoload。

#### 建议公开 API

具体签名在开工时结合现有代码确认，至少覆盖：

- 查询正式角色。
- 查询已发布任务。
- 提交派遣。
- 推进一天。
- 查询 ACTIVE 派遣。
- 查询未读或最新报告。

#### 验收

- 使用正式六名角色与 `task_missing_caravan`，不读取 `tests/fixtures/`。
- 能创建任务、派遣 1–2 人、推进两日、唯一选择结果、结算、生成报告、结束派遣。
- 至少验证完整成功、查明位置、搜索失败三条端到端路线。
- 角色到期结算后释放。
- 正常测试日志零 ERROR。
- V2 `runtime_chain_test.tscn` 继续通过。

#### 不包含

- UI。
- 主场景切换。
- 存档。
- JSON Importer。
- 其余五张任务。

#### 完成提交

`feat(v3): 组装正式游戏会话`

---

### [ ] V3 Task 6：实现核心循环 UI

#### 单一目标

让玩家通过正式界面完成查看、选人、派遣、等待和阅读报告。

#### 前置条件

- V3 Task 5 已完成。
- 执行本 Task 的 Agent 必须读取 `godot-ui-architect:godot-ui` skill。
- 美术未完成时允许使用明确标记的占位资产。

#### 界面主干

`公会主界面 → 打开任务文件 → 查看角色 → 选择 1–2 人 → 确认派遣 → 返回主界面 → 推进日期 → 打开报告`

#### 建议目录

- `ui/main/guild_main.tscn`
- `ui/main/guild_main.gd`
- `ui/tasks/task_document_view.tscn`
- `ui/characters/character_card_view.tscn`
- `ui/dispatch/dispatch_panel.tscn`
- `ui/reports/report_view.tscn`
- `ui/shared/` 下当前界面实际复用的最小组件

目录可在开工审计后收紧，禁止为了“以后方便”创建空目录或空组件。

#### 最低可见信息

任务文件：

- 名称
- 委托人
- 描述
- 目标
- 报酬
- 持续天数
- 推荐能力或风险提示
- 派遣人数限制

角色卡：

- 名称
- 职业
- 战斗
- 调查
- 交涉
- 当前是否被占用
- 当前已实现的持续状态

公会状态：

- 当前日期
- 金币
- 总声望
- ACTIVE 派遣
- 待阅读报告

#### 交互边界

- UI 只调用 GameSession 公开 API。
- 无效派遣在确认前给出明确原因。
- 已占用角色无法被选中。
- 到期前不展示最终结果。
- 报告必须展示结果事实、关键判定依据和持续后果。
- 关闭报告只改变报告阅读状态，不触发结算。

#### 视觉范围

首轮允许：

- 占位公会背景。
- 占位纸张与边框。
- 占位角色肖像。
- 文本或单色图标。

首轮禁止：

- 在 UI Task 中制作完整角色像素画。
- 粒子特效、复杂动画、全套主题系统。
- 多分辨率大规模适配。

#### 验收

- Jackie 可以只用鼠标完成完整循环。
- 1–2 人派遣限制生效。
- ACTIVE 角色状态及时更新。
- 连续推进两日后报告出现。
- 报告关闭后主界面的金币、声望、角色状态与情报反馈正确。
- UI 没有直接写入业务字段。
- `project.godot` 在本 Task 验收末尾切换到正式主场景。
- 正式主场景人工运行日志零 ERROR。

#### 不包含

- 最终美术品质。
- 音效与配乐。
- 存档与读档。
- 设置菜单。
- 新手教程。
- 其他任务接入。

#### 完成提交

`feat(v3): 实现核心循环界面`

---

### [ ] V3 Task 7：完成首张真实任务可玩验收

#### 单一目标

证明“失踪商队调查”从玩家信息、派遣判断、等待、报告到持续后果已经形成可重复验收的游戏体验。

#### 前置条件

- V3 Task 6 已完成。
- 正式主场景可以操作。

#### 自动验收

新增独立正式内容测试，至少覆盖：

- 六名角色资源全部加载。
- 五个结果各有一条确定性派遣命中。
- 两日等待前后生命周期正确。
- 五个结果结算后状态与报告正确。
- 重复结算、重复占用、到期前结算被拒绝。
- 正式运行路径不依赖 TEST_ONLY fixture。
- 正常端到端测试零 ERROR。

#### Jackie 人工验收脚本

Jackie 至少完成三轮：

1. 明确成功路线。
2. 部分成功或查明位置路线。
3. 搜索失败路线。

每轮检查：

- 派遣前能看出角色差异。
- 派遣选择有清晰理由。
- 等待期间无法提前得知结果。
- 报告能解释“选择 → 判定 → 结果”。
- 后果在主界面继续存在。
- 下一轮选择会受到占用、伤势、资源、关系或情报变化影响。

#### 通过标准

- Jackie 明确确认“首张真实任务可玩循环通过”。
- 自动测试与人工验收均通过。
- 发现的问题只在本 Task 范围内修复。
- 若问题要求新系统或改变策划规则，本 Task 标为 `[!]`，先询问 Jackie。

#### 不包含

- 第二张任务。
- Schema 最终冻结。
- JSON Importer。
- 存档。
- 最终美术。

#### 完成提交

`test(v3): 完成首张真实任务可玩验收`

---

### [ ] V3 Task 8：用第二张结构反例验证并冻结契约

#### 单一目标

接入“塌方矿井”，验证现有资产与判定结构能够表达单能力路线和双能力复合路线，然后冻结 V3 正式数据契约。

#### 选择“塌方矿井”的原因

- 它同时使用调查、交涉、战斗。
- 它包含单能力结果与双能力复合结果。
- 它继续使用队伍最高能力与默认 AND。
- 它不要求角色专属行为、职业特例或情报购买系统。
- 它能检验首张任务结构是否过拟合，同时保持本 Task 只验证数据表达能力。

#### 前置条件

- V3 Task 7 已完成。
- “塌方矿井”的任务卡与结果组卡具有明确稳定 ID、互斥结果、精确效果、任务终态和报告文本。

#### 允许修改

- `assets/data/tasks/` 下的第二张正式任务。
- `assets/data/results/` 下的第二个结果组及结果。
- 现有最小 Resource 与 Condition 类型确实无法表达时，进行最小扩展。
- `docs/project/architecture.md`，记录经过两张不同结构任务验证的 V3 字段契约。
- Task 8 专项测试。
- 三份规划记录。

#### 判定覆盖

至少覆盖：

- 只满足调查：通风道救援。
- 只满足交涉：侧井救援。
- 只满足战斗：强行开路。
- 调查＋战斗：安全清巢。
- 调查＋交涉：测绘侧井。
- 交涉＋战斗：协同开路。
- 三项均不足：任务失败。

若三项能力全部满足时存在多结果命中，必须回到策划结果互斥规则处理；禁止在 TaskResolutionSystem 中增加隐式优先级。

#### 验收

- 第二张任务沿现有正式链完成发布、派遣、等待、判定、结算和报告。
- 七类派遣分别唯一命中预期结果。
- 第一张“失踪商队调查”全部回归通过。
- 没有新增通用 RuleEngine、DSL 或结果优先级。
- `docs/project/architecture.md` 明确区分：
  - 已经由两张真实任务证明的正式字段。
  - 仍待角色行为题、职业题、情报购买题验证的字段。
- Jackie 人工确认第二张任务至少一条路线可完成。

#### V3 结束后仍不冻结

- 角色拒绝、违抗与自主行为。
- 职业特例。
- 可购买情报。
- OR / NOT / 嵌套 ConditionGroup。
- 随机权重。
- Event 链。
- 完整 JSON Importer。
- SaveSystem。
- 完整角色卡 Schema。

#### 完成提交

`feat(v3): 用第二张任务验证并冻结数据契约`

## 8. 依赖顺序

`V3 Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 → Task 7 → Task 8`

默认严格按顺序执行。跳过依赖必须由 Jackie 明确批准，并在 `findings.md` 记录原因与风险。

## 9. 单 Task 完成报告

每次完成后只报告：

1. 本 Task 实际完成的单一能力。
2. 修改的文件范围。
3. Godot 4.7.2 验收命令、预期、实际与退出码。
4. 明确未实现的后续内容。
5. 本地完成提交哈希。
6. 当前最靠前的下一 Task。

若失败或阻塞，报告必须在开头加粗显示“失败”或“阻塞”，并写清：

1. 已验证事实。
2. 真实错误。
3. 未发生的状态写入。
4. 需要 Jackie 决定的唯一问题。

## 10. V3 完成定义

同时满足以下条件，V3 才可标记完成：

- 八个 Task 全部 `[x]`。
- “失踪商队调查”与“塌方矿井”均使用正式资产。
- 玩家可通过正式 UI 完成派遣、等待、结算与报告。
- 结果后果会进入下一次判断。
- 两张不同结构任务均保持唯一结果命中。
- 正常人工场景零 ERROR。
- V2 回归测试继续通过。
- 每个 Task 有且只有一个本地完成提交。
- Jackie 完成人工验收。

V3 完成后停止。下一阶段应重新制定 V4 计划，再决定 JSON Importer、SaveSystem、角色行为题、职业特例、情报购买与最终美术生产。

## 11. 当前下一步

等待 Jackie 明确说：`执行 V3 Task 1`。
