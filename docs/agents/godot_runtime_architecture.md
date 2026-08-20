# 《公会》Godot正式开发架构

> 本文件是 Notion 项目真源的本地工作镜像。
>
> 来源：https://app.notion.com/p/3c07fb71ada481abb702fdf1a48e2eb3?pvs=204
>
> 同步时间：2026-08-20T05:25:00.128Z
>
> 用途：Godot 运行时架构总入口；Resource / Instance / System 边界；当前冻结技术契约；MVP 开发范围。
>
> 本地整理：2026-08-20 按正文顺序统一章节编号；未改变原文语义，Notion 真源未回写。

## Notion 页面属性

```json
{
  "date:最后核对日期:is_datetime": 0,
  "date:最后核对日期:start": "2026-08-18",
  "url": "https://app.notion.com/p/3c07fb71ada481abb702fdf1a48e2eb3",
  "一句话用途": "《公会今日照常营业》进入 Godot 正式开发时的运行时、数据资产、角色资产与 MVP 垂直切片架构基线；用于追溯当前技术结论并阻止旧方案混入。",
  "名称": "《公会》Godot正式开发架构",
  "文档类型": "系统设计",
  "最近编辑": "2026-08-20T05:25:00.129Z",
  "状态": "当前使用",
  "真源级别": "当前项目真源",
  "类型": "系统",
  "说明": "《公会》Godot 开发总入口。仅“已冻结继承”和“正式架构变更”构成当前技术契约；“待验证方案”和“未冻结问题”仅用于追踪，不得反向规定策划或被当作正式 Schema。",
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
<callout icon="📌" color="red_bg">
	**生效日期：2026-08-18。** 本页是《公会今日照常营业》Godot 正式开发总入口。只有“已冻结继承”和“正式架构变更”构成当前技术契约；“待验证方案”和“未冻结问题”只用于追踪，不得反向规定策划，也不得被当作正式 Schema。产品方向、角色正文、任务正文继续由对应策划真源决定。
</callout>
## 一、当前开发原则
采用**运行时垂直切片**：先让一张真实任务从生成、派遣、判定、结算到报告完整跑通，再根据真实共性抽象公共规则和工具。
当前主链：
```plain text
静态正式资产 Resource
        ↓
GameSession
        ↓
Task → Dispatch → Resolution → Result → Settlement
        ↓
Guild / Character & Relationship / Report & Intel
```
内容制作管线继续沿用当前项目真源：
```plain text
本地原稿 / Excel
→ Python 转表
→ 完整策划资产 JSON
→ 工作台管理、阅读、关联、校验与有限修改
→ Godot
```
Godot 侧的最终加载 / 转换方式、Importer 和 Runtime Schema 尚未冻结；本页不取消 JSON 层，也不让 Godot 反向定义策划字段。
## 二、已冻结继承
### 2.1 Node / Resource / Instance 分工
```plain text
Resource = 静态正式定义
Instance / Runtime Fact = 这一局实际发生的事实
Node System = 负责运行、读取和修改这些事实的系统
```
当前基础静态类型：
```plain text
CharacterAsset : Resource
TaskAsset : Resource
EventAsset : Resource
ResultGroupAsset : Resource
ResultAsset : Resource
```
### 2.2 原冻结 GameSession 基础结构
前序冻结结构为：
```plain text
GameSession
├─ GuildState
├─ TaskSystem
├─ TaskResolutionSystem
├─ ResultSettlementSystem
├─ StateRelationshipSystem
├─ ReportIntelSystem
└─ SaveSystem
```
该结构作为前序冻结依据保留；`DispatchSystem` 的加入见第三节正式变更。
### 2.3 TaskAsset / TaskInstance
`TaskAsset` 保存任务静态正式数据，单局运行不直接改写。
`TaskInstance : RefCounted` 表示同一静态任务在当前游戏中的一次具体实例，至少保存：
```plain text
instance_id
task_id
lifecycle_state
party_member_ids        # 前序冻结字段，迁移见第三节
运行中确实需要持久化的进度事实
final_result_id
```
同一 `TaskAsset` 可以在一局游戏中生成多个独立 `TaskInstance`。
### 2.4 任务生命周期当前口径
当前参考状态：
```plain text
PUBLISHED
IN_PROGRESS
COMPLETED
FAILED
ABANDONED
EXPIRED
INVALIDATED
```
这些名称用于描述生命周期，**不代表正式程序枚举已经冻结**。
当前规则：
- 已发布但尚未开始执行的任务可以主动放弃。
- 任务进入进行中后，玩家不能主动放弃。
- 当前参考迁移：`已发布 → 进行中 / 放弃 / 过期 / 失效`；`进行中 → 完成 / 失败 / 失效`。
### 2.5 任务生成边界
`TaskSystem` 只接受“合法的任务生成检查触发”，不在任务系统内部写死“每日刷新”等具体来源。
收到合法触发后，任务系统读取任务自身生成条件并请求对应系统判断；通过后才创建 / 发布任务实例。任务系统不自行复制或维护其他系统的状态真源。
### 2.6 任务、结果与结算边界
- 任务卡只保存任务主干与 Event 引用。
- 任务卡只保存一个 Result Group 引用。
- 任务卡中的委托报酬是发布时承诺值。
- 实际金币、损失、人物变化、关系变化、情报变化及其他后果由最终命中的具体 `ResultAsset` 定义。
- `TaskResolutionSystem` 决定最终命中的具体 `result_id`。
- `TaskSystem` 将 `final_result_id` 写入对应 `TaskInstance`。
- `ResultSettlementSystem` 读取 `ResultAsset` 并协调后果分发。
- `GuildState / StateRelationshipSystem / ReportIntelSystem` 各自拥有并实际写入自己的运行时状态。
```plain text
TaskAsset
    ↓
TaskInstance
    ↓
TaskResolutionSystem
    ↓
result_id
    ↓
TaskSystem 写入 final_result_id
    ↓
ResultSettlementSystem
    ↓
├─ GuildState
├─ StateRelationshipSystem
└─ ReportIntelSystem
```
### 2.7 GuildState / StateValue
DEMO 当前冻结的基础公会状态：
```plain text
GuildState
├─ Gold : StateValue
└─ TotalReputation : StateValue
```
`StateValue : Node` 负责稳定状态身份、当前值、读取 / 设置 / 增减与变化通知；外部系统统一通过 `GuildState` 的稳定 `state_id` 接口读写。
公开 API：
```javascript
func has_state(state_id: StringName) -> bool
func get_value(state_id: StringName) -> int
func restore_value(state_id: StringName, restored_value: int) -> void
func set_value(state_id: StringName, new_value: int) -> void
func add_value(state_id: StringName, amount: int) -> void
```
当前 DEMO 不实现完整库存、设施、债务、地区 / 势力声望、公会评级流程和特殊货币等扩展经营状态。
## 三、2026-08-18 正式架构变更
### 3.1 DispatchSystem 正式进入 GameSession
后续派遣系统已经明确独立职责，因此正式增补：
```plain text
DispatchSystem
= 管 DispatchInstance、派遣合法性和角色占用
```
当前 `DispatchInstance` 最小职责：
```plain text
dispatch_instance_id
task_instance_id
character_refs[]
status = ACTIVE / ENDED
started_at
ended_at
```
时间字段最终类型和单位仍等待时间系统冻结。
角色占用由当前 `ACTIVE DispatchInstance` 推导，不额外维护 `is_busy` 第二真源。
### 3.2 派遣成员真源迁移决议
前序冻结曾要求 `TaskInstance.party_member_ids` 保存本次实际派遣成员；后续派遣系统又形成独立 `DispatchInstance.character_refs[]`。
本次正式变更确定：
- **派遣成员的运行真源迁移到 ****`DispatchInstance`****。**
- `TaskSystem` 与其他系统需要本次实际参与角色时，通过关联的 Dispatch 记录读取。
- `TaskInstance.party_member_ids` 是否在实现迁移后删除，或仅保留为不可变历史快照，**尚未冻结**；在迁移实现前不得同时把两处当成可独立修改的真源。
### 3.3 变更后的当前顶层结构
```plain text
GameSession
├─ GuildState
├─ TaskSystem
├─ DispatchSystem
├─ TaskResolutionSystem
├─ ResultSettlementSystem
├─ StateRelationshipSystem
├─ ReportIntelSystem
└─ SaveSystem
```
## 四、当前待验证：角色数据资产方案 v0.1
本节来自 `角色卡策划原案.xlsx` 中埃利乌斯角色卡的第一次真实样本拆解。**它是候选结构，不是已冻结 Godot 契约。** 必须继续用第二名不同结构角色与两条不同结构任务验证后，才决定是否冻结具体模块。
### 4.1 已确认的上层原则
当前只确认以下原则：
- 角色静态定义使用 `CharacterAsset : Resource`。
- 静态角色定义与单局运行事实分离。
- 角色专属特例优先采用可组合数据 / 规则表达，而不是不断向 `CharacterAsset.gd` 增加专属字段。
- 玩家展示文案与程序可执行语义应分离，但具体 Schema 尚未冻结。
- 角色数据不依赖“每个角色一棵独立角色卡 Scene”才能成立。
### 4.2 埃利乌斯样本得到的候选模块
当前样本可暂时按以下概念理解：
```plain text
CharacterAsset
├─ Identity 候选
├─ Stats 候选
├─ Archive 候选
├─ Narrative 候选
├─ Rules / Exceptions 候选
└─ Links 候选
```
这些模块名称、数量、是否独立成为 Resource、字段归属均**未冻结**。
样本映射：
<table fit-page-width="true" header-row="true">
<tr>
<td>候选模块</td>
<td>埃利乌斯字段示例</td>
<td>当前用途判断</td>
</tr>
<tr>
<td>Identity</td>
<td>ID、名称、英文名、年龄、职业、身份、简要印象</td>
<td>静态基础资料</td>
</tr>
<tr>
<td>Stats</td>
<td>战斗、调查、交涉、冒险者等级、初始个人金币、初始声望</td>
<td>系统可能读取的基础定义</td>
</tr>
<tr>
<td>Archive</td>
<td>公开关系、弱线索、入会记录</td>
<td>玩家档案 / 情报内容</td>
</tr>
<tr>
<td>Narrative</td>
<td>叙事定位、核心动机、隐藏面、角色弧线</td>
<td>策划与叙事内容</td>
</tr>
<tr>
<td>Rules / Exceptions</td>
<td>公开特质、派遣前拒绝、违抗、自主行动、角色专属覆盖规则</td>
<td>候选运行规则来源</td>
</tr>
<tr>
<td>Links</td>
<td>个人事件、任务、其他资产的稳定引用</td>
<td>跨资产连接</td>
</tr>
</table>
### 4.3 公共规则与角色特例边界
通用疲劳、伤势、死亡和恢复规则继续归公共系统；角色资产只保存角色专属特例、覆盖或稳定引用。
因此不得把 `fatigue_progression / heavy_injury / rest_recovery` 等通用规则默认定义为每个角色的 `CharacterRuleSet` 内容。
### 4.4 角色运行事实
当前只冻结原则：**静态 CharacterAsset 不保存会在单局中持续变化的事实。**
例如以下内容属于运行事实范畴：
```plain text
当前伤势 / 疲劳 / 临时状态
连续派遣计数
属性修正
关系变化
揭露进度
死亡 / 离队等持续事实
```
这些事实由拥有对应状态职责的运行时系统维护。`CharacterRuntimeState` 是否作为独立对象存在、采用 Node / RefCounted / Resource 中哪一种、内部具体字段结构，均未冻结。
特别说明：
- 关系状态的正式写入权继续属于 `StateRelationshipSystem`。
- Flag 的作用域、拥有者、生命周期和写入权尚未冻结，不默认放入角色运行状态。
- “是否可派遣”是自动生成 / 派生信息，不作为角色卡手填真源；具体 `can_dispatch()` 接口归属后续确认。
### 4.5 角色卡 UI 候选方向
当前可继续验证：使用一个通用角色卡 View 读取角色静态数据、当前运行事实和已揭露信息。
但具体 `CharacterCardView.tscn` 名称、模块布局和是否所有角色完全共用一个 Scene 尚未冻结。
## 五、未冻结问题
以下内容不得因为本页存在而视为正式契约：
```plain text
CharacterAsset 的具体模块数量与字段 Schema
Character Runtime State 的具体 Godot 类型与字段
Character Trait 的程序效果结构
Character Rule 的条件 / 效果 Schema
Condition 的 AND / OR / NOT 与嵌套
规则优先级与同级冲突
Roll 与随机权重
状态叠加 / 刷新 / 冲突
Flag 作用域、拥有者与生命周期
隐藏信息阶段与揭露结构
JSON → Godot Runtime 的最终加载 / 转换契约
TaskInstance.party_member_ids 的迁移后最终去留
```
不得为了框架完整提前建设万能 `RuleEngine`、`ConditionEvaluator`、`EffectExecutor`、DSL 或统一 Variant 字段系统。
## 六、MVP 当前允许实现
当前可安全创建的是已经有稳定职责的运行时骨架与薄静态类型：
```plain text
res://runtime/
├── game_session.tscn
├── guild/
│   ├── guild_state.gd
│   └── state_value.gd
├── tasks/
│   ├── task_system.gd
│   ├── task_instance.gd
│   └── task_resolution_system.gd       # 只建薄接口
├── dispatch/
│   ├── dispatch_system.gd
│   └── dispatch_instance.gd
├── results/
│   └── result_settlement_system.gd     # 只建薄接口
├── characters/
│   └── state_relationship_system.gd    # 只建已有职责边界
├── reports/
│   └── report_intel_system.gd          # 只建已有职责边界
└── save/
    └── save_system.gd

res://assets/types/
├── character_asset.gd                  # 薄类型，不先拆六个子模块
├── task_asset.gd
├── event_asset.gd
├── result_group_asset.gd
└── result_asset.gd
```
第一条技术垂直切片仍然是：
```plain text
真实 TaskAsset
→ 创建 TaskInstance
→ 玩家选择角色
→ Dispatch Validation
→ 创建 DispatchInstance
→ TaskResolutionSystem 得到 result_id
→ TaskSystem 记录 final_result_id
→ ResultSettlementSystem 分发后果
→ Guild / Character & Relationship / Report & Intel 写入各自状态
→ DispatchInstance 结束并释放占用
```
## 七、暂不实现
当前不进入正式开发：
- 一比一复制策划卡全部字段的巨大 Resource 类。
- `CharacterIdentity / CharacterStats / CharacterArchive / CharacterNarrative / CharacterRuleSet / CharacterLinks` 等候选模块的正式文件化。
- 每个角色独立角色卡 Scene。
- 完整 JSON Importer 或正式 Runtime JSON Schema。
- 角色 / 任务内容编辑器插件。
- 通用 Condition / Effect / Flag / Weight 规则引擎。
- 完整库存、设施、债务、评级等经营系统。
- 为未来可能需要而预建的 Manager / EventBus / ServiceLocator。
Data Asset Editor 只保留为未来工具方向；在正式 Resource 契约稳定前不进入 MVP。
## 八、追溯与优先级
前序依据：
- <mention-page url="https://app.notion.com/p/3bc7fb71ada481be9ce9dd51fde72a36"/>：任务、结果、公会状态与运行时基础边界的前序冻结依据。
- <mention-page url="https://app.notion.com/p/3bb7fb71ada4814888f9ea8e28e501d4"/>：继续决定项目方向、产品验证顺序与策划边界。
- `角色卡策划原案.xlsx`：本轮角色数据结构候选方案的真实样本来源，目前只验证了埃利乌斯。
冲突处理：
1. 玩法、角色、任务创作内容冲突：回到对应策划真源，本页无权覆盖。
2. Godot 技术架构冲突：先判断本页内容属于“已冻结继承 / 正式变更 / 待验证 / 未冻结”哪一层。
3. 只有“已冻结继承”和“正式架构变更”可以覆盖更旧的技术结论。
4. “待验证方案”不得用于否定已冻结内容，也不得反向要求策划适配程序。
## 九、已冻结：TEST_ONLY 测试资产边界
本节仅用于在正式策划案未完成前支撑 Godot 垂直切片测试。测试资产沿用现有策划案结构中的稳定子集，但**不得自动升级为正式策划 Schema 或 Runtime Schema**。
<table fit-page-width="true" header-row="true">
<tr>
<td>资产</td>
<td>测试数量</td>
<td>冻结范围</td>
</tr>
<tr>
<td>测试角色</td>
<td>2</td>
<td>`id, name, profession, combat, investigation, negotiation, rank, public_traits, archive_text`</td>
</tr>
<tr>
<td>测试任务</td>
<td>1</td>
<td>`id, title, commissioner, description, objective, promised_reward, min_party_size, max_party_size, result_group_id`</td>
</tr>
<tr>
<td>测试结果组</td>
<td>1</td>
<td>仅用于连接测试任务与测试结果</td>
</tr>
<tr>
<td>测试结果</td>
<td>2</td>
<td>`result_id, report_text, guild_gold_change`</td>
</tr>
<tr>
<td>测试事件</td>
<td>0</td>
<td>首轮不使用</td>
</tr>
</table>
### 测试判定边界
首轮允许在测试代码 / fixture 中使用简单、明确的临时判定，例如 `combat_sum >= X`，仅用于命中不同 `Result`。不得据此创建通用 `Condition / Rule / Flag / Weight` 引擎或正式条件 Schema。
### 测试闭环
```plain text
看任务
→ 看角色
→ 选人
→ 派遣
→ 判定
→ Result
→ GuildState 变化
→ 显示 Result.report_text
```
### 明确边界
- `public_traits` 与 `archive_text` 首轮仅展示，不自动参与判定。
- `rank` 首轮仅展示。
- 不实现隐藏面、行为优先级、拒绝 / 违抗、自主行为、关系规则、疲劳伤势、Flag、揭露规则。
- 报告首轮直接显示 `Result.report_text`，不建立独立 `ReportAsset`。
- 所有测试数据必须明确标记 `TEST_ONLY`，正式策划资产出现后可以直接替换。
## 十、已冻结：新 Godot 仓库初始目录
当前正式工程只建立已被核心循环、冻结架构或测试闭环证明需要的目录。
```plain text
res://
├── runtime/
│   ├── game_session.tscn
│   ├── guild/
│   ├── tasks/
│   ├── dispatch/
│   ├── results/
│   ├── characters/
│   ├── reports/
│   └── save/
├── assets/
│   ├── types/
│   └── data/
├── ui/
├── tests/
│   └── fixtures/
├── addons/
└── docs/
```
### 目录职责
- `runtime/`：正式运行时系统与 Instance。
- `assets/types/`：已确认的静态 Resource 类型脚本。
- `assets/data/`：正式 `.tres` 数据资产；现阶段允许为空。
- `ui/`：正式 UI Scene 与脚本。
- `tests/`：GdUnit4 自动测试。
- `tests/fixtures/`：全部 `TEST_ONLY` 测试资产。
- `addons/`：GdUnit4 等第三方插件。
- `docs/`：从当前项目真源导出的工程 Markdown 文档。
### 当前禁止预建
不得提前创建 `rules/`、独立 `events/` 运行模块、`time/`、`inventory/`、`editor/`、`importer/`、`dialogue/`、`managers/` 等尚未被当前闭环证明需要的目录。
### 角色 / 任务 / 结果资产边界
`CharacterAsset / TaskAsset / EventAsset / ResultGroupAsset / ResultAsset` 的类型脚本可以位于 `assets/types/`；正式内容资产未冻结前不生产正式 `.tres`。测试内容只进入 `tests/fixtures/`，不得进入 `assets/data/`。
### 下一阶段文档要求
新仓库 `AGENTS.md` 必须参考旧仓库 `w7775p/2D-pixel-TrashSur` 的 `docs/superpowers/框架/AGENTS.md`，但只继承仍适用于《公会》的工程纪律；旧项目业务、旧系统和旧目录结构不得带入新仓库。
## 十一、[AGENTS.md](http://AGENTS.md) 状态
`AGENTS.md v0.2` 已完成审计修订方向：
- 项目阶段改为：概念验证与前期创作阶段；当前技术工作为 Godot 垂直切片验证。
- 明确策划真源、Godot 架构、工程规范三者职责边界。
- “明确禁止”调整为“当前阶段禁止擅自引入”，避免把未冻结系统永久否定。
- 删除 Scene 必须 `load().instantiate()` 的强制规则，只保留 Godot 生命周期相关陷阱。
- 保留最小路径、单一真相源、系统写入权、API/Signal、Resource 只读、TEST_ONLY、ID、验证、Git 规则。
下一步文档：`《公会》AGENTS.md v0.2`
定位：新 Godot 仓库根目录 Agent 行为规范。
当前确认修订：
1. 不承担策划真源，只约束工程行为。
2. 项目阶段与当前真源保持一致：概念验证与前期创作阶段。
3. 禁止项改为“当前阶段禁止擅自引入”。
4. 删除过强的 Scene 实现限制。
5. 保留单一真相源、系统写入权、API/Signal、Resource 只读、TEST_ONLY 隔离、ID 稳定、验证流程、Git 纪律。
## 十二、冻结补充：运行时对象模型 v0.1
当前冻结以下运行时对象关系：
```javascript
TaskAsset
  ↓
TaskInstance
  ↓
DispatchInstance
  ↓
TaskEventInstance（特殊任务可选）
  ↓
ResultAsset
  ↓
ResultInstance
  ↓
Settlement
  ↓
GuildState / CharacterState / Report
```
### TaskInstance
- 普通任务允许根据任务卡字段重复生成。
- 特殊任务根据任务卡唯一性字段限制重复生成。
### DispatchInstance
- 保存玩家每次派遣决策历史。
- 同一任务重新派遣生成新的 DispatchInstance，不覆盖旧记录。
### Result
- ResultAsset：策划配置的结果模板，包含条件与输出内容。
- ResultInstance：运行时实际发生的结果记录。
- 结果判定采用条件筛选，符合条件后输出对应结果。
- 同一任务结果条件互斥，不存在多个结果同时触发。
### 多阶段任务
- 仅特殊任务启用。
- 任务卡通过中途事件引用字段配置 TaskEventInstance。
- 未配置中途事件的任务直接进入最终结果。
## 十三、2026-08-20 正式冻结：Result 条件与结果运行时
### 13.1 结果选择原则
- ResultGroup 内 ResultAsset 条件必须互斥。
- 不设计结果优先级排序。
- 策划必须保证同一组结果不会同时满足，也不会出现无结果命中（除非明确设计）。
运行流程：
```plain text
DispatchInstance
↓
读取派遣角色三项能力与特殊条件
↓
检查 ResultAsset 条件
↓
唯一命中
↓
生成 ResultInstance
```
### 13.2 ResultAsset / ResultInstance 分工
```plain text
ResultAsset = 策划配置的结果规则与内容
ResultInstance = 本次游戏实际发生的结果记录
```
ResultAsset 包含：
- 条件集合
- 输出文本
- 状态变化定义
- 报告内容引用
ResultInstance 保存：
- 命中的 ResultAsset 引用
- 对应 DispatchInstance
- 本次实际结算记录
### 13.3 ConditionResource 模块化条件结构
结果条件采用 Resource 组合方式，不使用固定字段扩展。
```plain text
ResultAsset
├─ Conditions : Array[ConditionResource]
└─ Effects : Array[EffectResource]
```
ConditionResource 基类负责判断接口，具体条件按需求扩展：
- AbilityCondition
- CharacterCondition
- RelationshipCondition
- GuildStateCondition
- EventCondition
MVP 逻辑：默认 AND；需要 OR 时使用 ConditionGroup，不直接让单个条件承担复杂逻辑。
### 13.4 EffectResource 模块化结算结构
Result 不直接修改状态。
```plain text
ResultInstance
↓
ResultSettlementSystem
↓
EffectResource
↓
对应状态系统
```
Effect 示例：
- GoldEffect
- ReputationEffect
- CharacterStateEffect
- UnlockEffect
### 13.5 当前冻结运行时对象
```plain text
TaskInstance
DispatchInstance
EventInstance（特殊任务扩展）
ResultInstance
```
静态资产：
```plain text
TaskAsset
EventAsset
ResultGroupAsset
ResultAsset
CharacterAsset
```
## 十四、2026-08-20 架构修正冻结
### 14.1 TaskInstance 派遣成员真源修正
`TaskInstance.party_member_ids` 不再作为运行时真源。
正式规则：
```plain text
TaskInstance
├─ instance_id
├─ task_id
├─ lifecycle_state
├─ final_result_id
└─ runtime_progress

DispatchInstance
├─ dispatch_instance_id
├─ task_instance_id
└─ character_refs[]
```
实际派遣成员只允许从 `DispatchInstance.character_refs[]` 获取。
`TaskInstance` 如需保存历史快照，仅作为不可变记录，不参与逻辑读取。
### 14.2 Result 判定链修正
结果判定正式采用：
```plain text
TaskInstance
↓
DispatchInstance
↓
TaskResolutionSystem
↓
ResultGroupAsset
↓
ConditionResource 检测
↓
ResultAsset
↓
ResultInstance
↓
ResultSettlementSystem
```
`ResultGroupAsset` 是结果筛选入口；`ResultAsset` 是单个具体结果规则与内容；`ResultInstance` 是本次游戏实际发生事实。
### 14.3 Result 条件与效果模块冻结
ResultAsset 不使用固定字段堆叠条件，采用组合资源：
```plain text
ResultAsset
├─ conditions : Array[ConditionResource]
├─ effects : Array[EffectResource]
└─ report_reference
```
Condition：
- 默认逻辑为 AND。
- 复杂 OR 使用 ConditionGroup。
- 不引入通用规则引擎。
Effect：
- 结果不直接修改状态。
- 统一由 SettlementSystem 分发至 GuildState、CharacterState、Relationship、Report 等系统。
### 14.4 当前开发冻结范围
以下内容达到开发要求，可进入 Godot 骨架实现：
```plain text
TaskAsset
TaskInstance
DispatchInstance
ResultGroupAsset
ResultAsset
ResultInstance
ConditionResource
EffectResource
Settlement流程
GuildState
```
CharacterAsset 继续保持最小读取接口，不在本阶段扩展完整角色编辑结构。
</content>
