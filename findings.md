# 项目发现与约束

## 2026-08-23 V2 Task 16 完整 Vertical Slice 结论

- 最终验收使用独立 `runtime_chain_test.tscn`，只运行成功链，避免 Task 12 与 Task 14 的预期错误分支污染“零运行时错误”证据。
- TEST_ONLY 角色 A 在验收脚本中以调查 12 创建，没有改写 CharacterAsset fixture 或静态 Resource。
- ResultGroupAsset 负责结果筛选入口，TaskResolutionSystem 返回稳定 result_id；验收脚本只按该 ID 读取对应 ResultAsset 引用。
- ResultInstance 保存本次结果与已确定效果，ResultSettlementSystem 通过 GuildState 写入 100/5，ReportIntelSystem 再生成确定报告。
- 派遣在链尾通过 DispatchSystem 显式结束，角色占用随 ACTIVE 状态消失，没有第二占用真源。
- Task 0–16 的功能能力已在 Godot 4.7.2 中形成完整、确定、无随机的运行时垂直切片；2026-08-25 Jackie 通过 F6 人工运行独立场景并确认预期输出。当前 V2 到 Task 16 为止，不创建 Task 17。

## 2026-08-23 V2 Task 15 ReportIntelSystem 结论

- `ReportIntelSystem` 当前是无持久状态的薄 Node，只把一个已确定结果转换为玩家可读纯文本。
- 报告首行直接使用 ResultAsset.report_text，后续行按 ResultInstance.resolved_effects 的确定顺序解释金币与声望变化。
- 系统要求 ResultAsset.id 与 ResultInstance.result_asset_id 一致，避免使用错误静态内容解释运行结果。
- 当前只支持 GoldEffect 与 ReputationEffect 的具体文本，没有引入 ReportAsset、模板 DSL、文案注册表或报告历史状态。
- Task 15 验收链先完成效果结算再生成文本；ReportIntelSystem 本身不重复执行效果，也不修改 GuildState。

## 2026-08-23 V2 Task 14 ResultSettlementSystem 结论

- `ResultSettlementSystem` 只消费 ResultInstance 已确定的 `resolved_effects`，没有重新选择 ResultAsset 或读取条件。
- GoldEffect 与 ReputationEffect 分别映射到 GuildState 的 `gold`、`total_reputation` 稳定 ID；效果本身不直接修改状态。
- 系统先验证全部效果类型再开始写入，避免支持效果已生效后才遇到未知效果的半结算。
- 重复结算事实由系统按 `dispatch_instance_id` 独占记录；首次成功后，同一派遣的后续结算请求明确失败。
- 当前采用两条具体类型分支，没有创建 EffectExecutor、注册表、DSL 或面向未来效果的通用分发框架。

## 2026-08-23 V2 Task 13 GuildState 与 StateValue 结论

- `GuildState` 是金币与总声望的唯一公开读写边界；稳定 ID 固定为 `gold` 与 `total_reputation`。
- 每个 `StateValue` Node 只持有一个状态 ID 和整数当前值，普通设置与增减通过 `value_changed` 通知已经发生的变化。
- `restore_value()` 直接恢复已保存事实，不模拟一次游戏内数值变化；SaveSystem 与具体存档格式仍未进入当前范围。
- GuildState 在创建时注册两个 StateValue 子节点；状态集合保持私有，未知 ID 会明确报错。
- 当前没有加入库存、设施、债务、评级、地区声望、特殊货币或通用状态 Schema。

## 2026-08-23 V2 Task 12 TaskResolutionSystem 结论

- `TaskResolutionSystem` 是无持久状态的 Node；输入为 DispatchInstance 与 ResultGroupAsset，输出只保留稳定 `result_id`。
- 三项队伍能力从 `DispatchInstance.character_refs` 即时求和；当前 ConditionResource 接口只接收调查总值，因此战斗与交涉总值没有被猜测性扩展为新条件 Schema。
- ResultAsset 内条件采用当前冻结的默认 AND；空条件集合不视为隐式成功或 fallback。
- 结果组必须恰好命中一个 ResultAsset；零命中与多命中都会显式报出命中数量并返回空 ID，不依赖结果顺序或优先级。
- 系统没有写入 TaskInstance、创建 ResultInstance 或执行 EffectResource；这些职责继续留在 TaskSystem、后续组装与 ResultSettlementSystem。

## 2026-08-23 V2 Task 11 DispatchSystem 结论

- `DispatchSystem` 使用 Node 独占 DispatchInstance 集合；创建、读取与状态迁移都经过系统公开 API。
- 角色占用由全部 ACTIVE 实例的 `character_refs` 实时推导，没有维护可独立修改的 `is_busy` 第二真源。
- ENDED 实例保留在派遣历史中，同时立即释放角色；同一角色随后可加入新的 ACTIVE 派遣。
- 派遣 ID 由任务实例 ID 与系统内递增序列确定性生成；当前没有引入未冻结的时间字段。
- 任务结果选择继续属于 Task 12，本系统只处理派遣合法性、持有和 ACTIVE/ENDED 生命周期。

## 2026-08-23 V2 Task 10 TaskSystem 结论

- `TaskSystem` 使用 Node 承担 TaskInstance 的创建、持有和最终结果写入权，实例集合保持私有。
- 实例 ID 由系统内递增序列确定性生成，格式为 `<task_id>_instance_<sequence>`；同一 TaskAsset 可产生多个互相独立的实例。
- 新实例初始生命周期使用当前参考状态 `PUBLISHED`，没有引入正式生命周期枚举或额外迁移接口。
- `final_result_id` 只通过 `record_final_result()` 写入；本 Task 没有让派遣或结果系统直接修改 TaskInstance。
- 任务生成条件、每日刷新、派遣和结果选择继续留给各自后续职责，没有在 TaskSystem 中预建框架。

## 2026-08-23 V2 Task 9 ResultInstance 结论

- `ResultInstance` 使用 `RefCounted` 保存一次已经确定的结果事实，最小字段严格保持为结果资产 ID、派遣实例 ID 与已确定效果引用。
- `resolved_effects` 使用 `Array[EffectResource]` 并通过 `assign()` 复制容器；运行记录调整自身数组顺序时不会改写静态 `ResultAsset.effects` 数组。
- 数组元素继续引用只读 EffectResource，当前没有复制或修改效果 Resource；Task 14 的结算系统将消费这些确定引用。
- 结果选择、效果执行、报告生成和重复结算保护仍属于后续系统，本 Task 没有增加对应状态或接口。

## 2026-08-23 V2 Task 8 DispatchInstance 结论

- `DispatchInstance` 使用 `RefCounted` 保存一次派遣决定，并以 `Array[CharacterAsset]` 强类型保存实际角色引用。
- 派遣成员运行真源只在 `DispatchInstance.character_refs`；TaskInstance 继续没有 `party_member_ids` 或任何可变成员副本。
- `status` 暂用 `StringName` 保存当前冻结的 ACTIVE/ENDED 状态值；状态迁移与角色占用推导留给 Task 11 的 DispatchSystem。
- `started_at / ended_at` 的类型与单位仍未冻结，本 Task 没有添加时间字段。

## 2026-08-23 V2 Task 7 TaskInstance 结论

- `TaskInstance` 使用 `RefCounted` 表达单局中一次已经发生的任务实例事实，静态 `TaskAsset` 保持只读。
- `lifecycle_state` 暂以 `StringName` 保存参考状态名称，避免在生命周期契约尚未冻结时引入正式枚举。
- `runtime_progress` 为每个实例独立持有的 Dictionary；同一 `task_id` 的两个实例可分别修改进度、生命周期与最终结果，没有共享可变事实。
- 派遣成员继续留给 Task 8 的 `DispatchInstance.character_refs[]`，TaskInstance 没有增加 `party_member_ids` 第二真源。

## 2026-08-23 V2 Task 6 ResultGroupAsset 结论

- Jackie 已确认允许最小互补条件；新增 `AbilityBelowCondition` 后，`>= 10` 与 `< 10` 将整数调查能力域完整分为成功、失败两支，不需要 fallback、优先级、OR/NOT 或通用规则引擎。
- `TaskAsset.result_group` 已从通用 Resource 收紧为 `ResultGroupAsset`；任务 fixture 可沿强类型引用读取两个 ResultAsset。
- ResultGroupAsset 当前只保存 `id` 与 `Array[ResultAsset]`，不执行筛选或排序；结果选择仍归 Task 12。

## 2026-08-23 V2 Task 6 条件完备性阻塞

- 二元结果要同时满足“互斥”和“无遗漏”，条件集合必须能表达一对互补谓词，例如 `investigation >= 10` 与 `investigation < 10`。
- 当前唯一具体条件 `AbilityCondition` 只支持 `>= value`。两个 `>=` 条件无法形成互补分区；空条件作为失败分支会引入尚未冻结的 fallback 或优先级语义。
- 最小结构化方案是增加一个只表达 `< value` 的具体 `AbilityBelowCondition`，继续沿用组合 Resource，不引入 OR/NOT、ConditionGroup、优先级或通用规则引擎。
- 该能力超出 Task 6 的既定范围“结果组静态连接且不执行条件”，因此在 Jackie 明确决定前暂停，避免通过无效 fixture 伪造验收。

## 2026-08-23 V2 Task 5 ResultAsset 发现

- 自定义 Resource 强类型数组可在 `.tres` 中使用 `Array[ExtResource("类型脚本 ID")]([...])` 保存；本次已由 Godot 4.7.2 实际加载验证 `ConditionResource` 与 `EffectResource` 两类数组。
- ResultAsset 只组合静态定义：一项 AbilityCondition、GoldEffect、ReputationEffect 与首轮 `report_text`；没有执行条件、修改状态或选择结果。
- `report_text` 只服务当前 TEST_ONLY 闭环，仍不代表完整报告资产 Schema 已冻结。

## 2026-08-23 V2 Task 4 最小效果发现

- `EffectResource` 当前只承担 ResultAsset 后续所需的强类型引用边界，不保存通用字段，也不提供执行接口；效果语义由 `GoldEffect` 与 `ReputationEffect` 的具体类型表达。
- 两个具体效果只保存确定性整数 `amount`，没有直接写入状态，因此尚未产生 GuildState 所有权或重复结算问题。
- 两个 TEST_ONLY fixture 分别稳定加载 `gold +100` 与 `reputation +5`，没有引入 EffectExecutor、结算编排或 DSL。

## 2026-08-23 V2 Task 3 最小条件发现

- 当前最小条件契约只需要 `ConditionResource.is_met(int)` 与 `AbilityCondition.value`，传入一个已经明确的调查能力值即可完成验收；Dispatch 能力聚合和通用上下文接口继续留到真实调用链出现后决定。
- 直接调用 `ConditionResource` 基类会显式报告配置错误并返回 `false`，避免把未实现的具体条件静默当成成功。
- 两个 TEST_ONLY fixture 分别保存阈值 10 与 13；调查能力 12 对应结果稳定为 `true` 与 `false`，没有引入随机、OR/NOT、ConditionGroup 或 DSL。

## 2026-08-23 V2 Task 2 目录迁移发现

- Task 1 的全局类缓存陷阱同样适用于 `TaskAsset`；目录迁移后先执行 Godot 项目扫描，可让 `.godot/global_script_class_cache.cfg` 从旧路径更新到 `res://assets/types/task_asset.gd`。
- `task_asset.gd.uid` 在迁移中保持 `uid://b2gq7gelqbfes`，稳定资源身份未改变。
- Task 2 最终验收通过：fixture 从新路径加载，正确读出 `test_abandoned_hospital`、标题“废弃医院调查”、描述、`repeatable = false`，且 `result_group` 与 `event_reference` 继续为空。

## 2026-08-23 V2 Task 1 目录迁移发现

- 移动带 `class_name` 的 GDScript 后，`.godot/global_script_class_cache.cfg` 可能继续保存旧路径，使新脚本报 `Class hides a global script class`，调用方也会报告无法从旧路径解析全局类。
- 正确处理是让 Godot 编辑器执行项目扫描刷新本地缓存，再重新运行单脚本检查与主场景验收；`.godot/` 仍是忽略的本地生成目录，不进入业务改动。
- `character_asset.gd.uid` 在迁移中保持 `uid://bsf7hvjievcsl`，稳定资源身份未改变。
- Task 1 最终验收通过：fixture 从 `res://assets/types/character_asset.gd` 加载，角色名称为“角色A”，`investigation = 10`。

## 2026-08-23 规划真源迁移

- `task_plan.md`、`progress.md`、`findings.md` 已迁入 `D:\Godot\guild_today` 根目录。
- 本地 Godot 仓库的三个文件成为后续本地任务的规划真源；ChatGPT 项目镜像暂作备份。
- 根 `AGENTS.md` 已将读取路由切换到仓库根目录；根 `README.md` 已增加规划文件导航。
- 本次迁移只复制规划文件并更新入口文档，未执行任何 Task。

## 2026-08-23 Task 0–16 V2 重规划发现

- Jackie 要求基于当前项目变化生成新的 Task 0–16 计划；本轮只修改规划文件，不执行任何 Godot 功能任务。
- 当前实际能力：Task 0 已完整验收；CharacterAsset 与 TaskAsset 已由 Godot 4.7.2 实际加载验收，但脚本仍位于 `resources/`，与冻结目录 `assets/types/` 不一致。
- 当前仓库文档已完成 DOC-1～DOC-5，唯一入口为根 `AGENTS.md`，正文位于 `docs/project/`；新计划不再混入已结束的 DOC 任务正文。
- 旧计划存在依赖倒置：Task 3 要求 ResultAsset 保存 Condition/Effect 引用，但 ConditionResource 与 EffectResource 被排在 Task 10、12；若坚持强类型引用，必须提前提供最小基类，或调整任务顺序。
- 冻结架构要求：静态类型进入 `assets/types/`；运行时按 `runtime/tasks/`、`runtime/dispatch/`、`runtime/results/`、`runtime/guild/`、`runtime/reports/` 分区；派遣成员真源只在 `DispatchInstance.character_refs[]`。
- TaskInstance 当前冻结字段为 `instance_id`、`task_id`、`lifecycle_state`、`final_result_id`、`runtime_progress`；生命周期名称仍是参考口径，不应在计划中提前冻结正式枚举。
- 条件与效果采用组合 Resource，但禁止建设通用 RuleEngine、DSL、ConditionEvaluator 或 EffectExecutor；第一条切片只允许最小具体条件和效果。
- `ReportSystem` 应对齐为 `ReportIntelSystem` 薄边界；完整测试链必须显式经过 ResultGroupAsset 与 ResultAsset。
- 当前 Git 工作区同时包含 DOC 文档变更与 Task 1–2 的既有代码/fixture 变更；新计划不得把这些本地文件误判为已提交状态。
- 会话恢复脚本尝试 1 次失败：当前环境没有可直接调用的 `python` 命令；已通过重新读取规划文件、项目文档与 Git 状态完成等价上下文恢复，不再重复同一失败调用。
- V2 计划首次替换尝试失败：`apply_patch` 不允许在同一补丁中同时删除并新增同一路径；改为先删除旧 `task_plan.md`，再用独立补丁创建新文件，不重复原操作。
- V2 已落盘：Task 0 保持完成；Task 1–2 改为待校准；旧 Task 10/12 的 Condition/Effect 能力提前为新 Task 3/4；其余能力按依赖映射到 Task 5–16。
- 新计划将旧文档重构任务从活跃清单移除，但没有删除历史记录；`progress.md` 与本文件仍保留 DOC-1～DOC-5 的完整决策与验收证据。

## DOC-5 全局验收与 Task 0–16 自审（已完成）

- 全局验收通过：唯一根 `AGENTS.md`；`docs/project/` 四份正文齐全；旧 `docs/agents/` 已删除；旧路径/文件名、Markdown 断链、尾随空格、敏感信息均无命中。
- 文档职责链已闭合，DOC-1～DOC-5 全部完成；没有执行 Godot 功能任务，没有 commit 或 push。
- Task 0：当前 Godot 4.7.2 加载与运行证据有效；`findings.md` 中原“尚未实际启动”的段落属于历史记录，不再代表当前状态。
- Task 1–2：实际脚本在 `resources/`，冻结架构规定静态类型脚本在 `assets/types/`；需要在后续独立变更中迁移并重新验收，不能在文档任务中偷偷移动代码。
- Task 3–4：计划路径改为 `assets/types/`；Task 3 仍暂停，ResultAsset 条件/效果仅保存引用，不提前执行判定。
- Task 5–7：计划路径改为架构规定的 `runtime/tasks/`、`runtime/dispatch/`、`runtime/results/`；TaskInstance 字段改为 `task_id`、`lifecycle_state`、`final_result_id`、`runtime_progress`，不把派遣成员放入 TaskInstance 真源。
- Task 8–9、11、13–14：计划补齐架构规定的 tasks、dispatch、guild、results 子目录。
- Task 10、12：计划明确只做具体 AbilityCondition、GoldEffect、ReputationEffect 最小接口，禁止通用 RuleEngine / DSL / 执行器。
- Task 15：计划改为 `ReportIntelSystem` 薄边界；Task 16：完整链补入 `ResultGroupAsset → ResultAsset`。
- 以上是规划修正，不代表任何后续 Task 已获授权或已执行。

## DOC-4 清理记录（已完成）

- 四份目标正文已按 DOC-1 矩阵重新划定职责：架构、工程规则、协作流程、排错记录各自只有一个正文主人。
- 从 `architecture.md` 移出架构追溯/决策优先级，归入 `workflow.md` 附录；移出 TEST_ONLY，归入 `engineering_rules.md` 附录；删除 AGENTS 状态同步噪音。
- 从 `workflow.md` 移出生命周期提醒，归入 `known_traps.md`；移出 TEST_ONLY 与 Git 纪律，归入 `engineering_rules.md`；完成汇报章节顺延为第 7 章。
- 四份文档只保留精简真源链接、同步时间与职责说明；已清理 Notion 导出标签、原始层级、旧工作台链接和重复协作正文。
- 验收证据：目标四文件均存在；包装/旧路径/旧文件名扫描无命中；architecture 的 MVP、engineering 的 TEST_ONLY、workflow 的汇报规范、known_traps 的 KT-24 均保留；`git diff --check` 通过。
- 本 DOC 未修改 Godot 功能文件，未执行 Task 3，未执行 Git 提交或推送。

## 2026-08-23 文档体系重构决策

- 当前待整理输入实际为 7 份文件：根 `AGENTS.md`、根 `README.md`、`docs/agents/README.md` 与四份正文镜像。
- 目标结构为根目录单一 `AGENTS.md`、根 `README.md` 和 `docs/project/` 下四份职责明确的正文。
- 人类读取链由 `README.md` 进入；Agent 读取链由 `AGENTS.md` 进入，并根据任务类型读取对应正文。
- `AGENTS.md` 只保存读取路由和不可绕过的执行闸门；详细架构、工程规则、协作流程与排错知识分别归入四份正文。
- 文档重构登记为 `DOC-1～DOC-5`，当前仅登记、未授权执行；Task 3 保持暂停。

## DOC-1 内容归属矩阵（已完成）

| 当前文件/章节 | 目标归属 | 处理原则 |
|---|---|---|
| 根 `AGENTS.md`：项目范围、唯一目录、读取入口、执行闸门 | 根 `AGENTS.md` | 保留为 AI 入口；只保留路由、阶段、权限和高风险操作摘要 |
| 根 `AGENTS.md`：详细 Resource、Signal、TEST_ONLY、生命周期、Git 规则 | `docs/project/engineering_rules.md` 或 `known_traps.md` | 迁移到唯一正文；入口只保留一句不可绕过的摘要 |
| 根 `README.md`：项目介绍、当前进度、启动方式、目录结构 | 根 `README.md` | 保留并改造成面向人的项目说明与文档地图 |
| `docs/agents/README.md`：读取顺序、同步范围 | 根 `AGENTS.md` 与根 `README.md` | 分别保留 Agent 路由和人类导航；原索引文件最终移除 |
| `godot_runtime_architecture.md`：当前原则、Resource/Instance/System、GameSession、Task/Dispatch/Result/Settlement | `docs/project/architecture.md` | 保留架构正文，去除 Notion 页面包装和协作规则 |
| `godot_runtime_architecture.md`：角色资产候选、未冻结问题、MVP、暂不实现 | `docs/project/architecture.md` | 保留冻结状态与未冻结边界，明确“候选”不得当作正式 Schema |
| `godot_runtime_architecture.md`：TEST_ONLY、仓库初始目录、运行时对象模型、Result 条件/效果冻结 | `docs/project/architecture.md` 与 `docs/project/engineering_rules.md` | 架构边界归 architecture；编码与测试约束归 engineering_rules |
| `godot_runtime_architecture.md`：AGENTS 状态、Notion 追溯与重复优先级 | 根 `AGENTS.md`、`workflow.md` 或删除 | 当前状态由任务清单维护；协作决策归 workflow；同步噪音删除 |
| `engineering_rules.md`：工程铁律、命名目录、数据生产链、最低完成标准 | `docs/project/engineering_rules.md` | 保留为代码实现唯一正文，去除页面属性和原始层级 |
| `notion_agents.md`：当前阶段、读取顺序、权责优先级、修改前后、完成汇报 | `docs/project/workflow.md` 与根 `AGENTS.md` | 强制闸门摘要放入口；流程细节和决策顺序归 workflow |
| `notion_agents.md`：Godot 生命周期提醒、TEST_ONLY、Git | `known_traps.md` 与 `engineering_rules.md` | 生命周期陷阱合并到 known_traps；TEST_ONLY/Git 规则归 engineering_rules |
| `known_traps.md`：KT-01～KT-24 与自查入口 | `docs/project/known_traps.md` | 保留编号、问题、正确做法和自查清单；删除旧项目说明与冗余来源包装 |
| 所有 Notion 页面属性、原始层级、重复 `<content>` 包装 | 各目标文档顶部的精简来源说明 | 只保留真源链接、同步日期和适用范围，不保留网页导出噪音 |

### DOC-1 归属决策

- 唯一正文主人：架构归 `architecture.md`，代码规则归 `engineering_rules.md`，协作流程归 `workflow.md`，陷阱归 `known_traps.md`。
- `AGENTS.md` 允许重复高风险闸门摘要，但不复制正文细节。
- `README.md` 只负责项目导航，不承担技术规则的权威解释。
- 当前输入实际为 7 份文件；`docs/agents/README.md` 已纳入迁移范围。

## DOC-2 迁移记录（已完成）

- 四份正文已迁移到 `D:\Godot\guild_today\docs\project\`，目标文件名与归属矩阵一致。
- 迁移采用保留内容的文件移动，没有在 DOC-2 中做正文清理或入口重写。
- `docs/agents/README.md` 暂留，等待 DOC-3 入口重写和 DOC-5 全局验收后处理。

## DOC-3 入口重写记录（已完成）

- 根 `AGENTS.md` 现在只承担 AI 入口职责，读取路由已切换到 `docs/project/`。
- 根 `README.md` 现在只承担项目说明和人类文档导航职责。
- 入口层保留高风险执行闸门摘要，详细工程规则继续由正文文档负责。
- DOC-3 验收确认：入口文件共 44 行和 35 行，旧 `docs/agents/` 路径和旧文件名不再被入口引用。

## Notion 项目真源本地镜像

- 已同步 4 个指定页面：Godot 正式开发架构、正式工程铁律、Notion AGENTS.md、known_traps。
- 本地目录：`D:\Godot\guild_today\docs\agents`。
- 根 `AGENTS.md` 已增加开工前读取顺序；Notion 页面仍是真源，本地文件作为 Agent 工作镜像。
- 镜像保留完整正文、页面属性、原始层级、来源链接与同步时间。
- 页面中没有附件或数据库；架构页的两个额外追溯页面仅保留链接，未扩展同步。
- 本地架构镜像的顶级章节编号已整理为“一”至“十四”；重复的 `5.x` 已分别整理为 `13.x` 与 `14.x`。
- 已使用 GitHub Desktop 提交并推送到 `main`；提交为 `d13378b docs: 同步项目真源并整理章节编号`。

## 用户要求

- 从原 ChatGPT 对话《初始化Godot骨架》中恢复已拆分任务。
- 创建可跨会话使用的长期任务清单。
- 本次只整理，不执行任何 Godot 开发任务。
- 后续只有 Jackie 明确说“执行”后才能执行指定任务。
- 每次只做一件事，并在完成后报告：做了什么、没做什么、下一步建议。
- `git commit` 与 `git push` 永远需要事先询问。
- 所有新增或修改的代码必须带简明中文注释；注释解释意图、边界或关键流程，不做无意义逐行翻译。

## 原对话发现

- 原对话共拆分 Task 0–16，共 17 个任务。
- Task 0 已建立 `project.godot → vertical_slice_test.tscn → vertical_slice_test.gd` 文件链。
- 原对话明确说明没有实际启动 Godot 客户端，因此 Task 0 尚未满足验收条件。
- 更早的执行曾创建若干 Resource、Runtime 和 System 占位文件，但没有完整运行验证；不能据此将对应 Task 标记完成。
- Task 1–16 在当前清单中统一保持待授权状态。

## 冻结架构

- Resource：静态策划定义。
- Instance / Runtime：本局游戏已经发生的事实。
- System：管理运行逻辑。
- 第一阶段只实现核心运行链，不制作完整 UI、完整编辑器、存档或未冻结系统。

## 核心运行链

`TaskAsset → TaskInstance → DispatchInstance → TaskResolutionSystem → ResultGroupAsset → ResultAsset → ResultInstance → ResultSettlementSystem → GuildState → Report`

## 任务管理决策

| 决策 | 理由 |
|---|---|
| 使用根目录 `task_plan.md` 作为唯一任务真源 | 可跨会话恢复，避免聊天上下文丢失 |
| 状态区分为待授权、待验收、执行中、已完成 | 把“有文件”和“通过验收”明确分开 |
| 当前任务设为“无” | 防止创建清单后被误认为已经授权执行 Task 1 |
| 验收必须包含 Godot 实际加载或运行结果 | 静态文件检查不足以证明功能成立 |

## 来源

- ChatGPT 对话：《初始化Godot骨架》
- 对话 ID：`6a870121-49cc-83ea-95f0-727c5c1e6c79`
- 提取日期：2026-08-20

## 当前未决事项

- Task 0 已完成：Godot 编辑器成功加载项目，无界面启动退出码为 0，并输出 `Guild Today Open As Usual boot success`。
- Task 1–16 仍等待单独授权。

## Task 0 验收证据

- 本地仓库：`D:\Godot\guild-workbench`
- 当前分支：`feature/godot-runtime-skeleton`
- Godot 配置：`run/main_scene = res://tests/vertical_slice_test.tscn`
- 主场景：`tests/vertical_slice_test.tscn`，根节点 `VerticalSliceTest`
- 启动脚本：`tests/vertical_slice_test.gd`
- 实际输出：`Guild Today Open As Usual boot success`
- 实际退出码：`0`
- 本次没有新增或修改 Godot 业务代码；中文注释约束从后续代码任务开始强制执行。
- Godot 首次运行后工作区出现自动生成内容：`.godot/`、多个资源 `.uid` 文件，以及 `project.godot` 的格式注释与 `config/features=PackedStringArray("4.7")`。
- 这些变更未提交，也未被当作业务 Task 的完成证据；`.gitignore` 当前没有忽略 `.godot/` 与 `*.uid`，后续需单独决定版本控制策略。

## 2026-08-20 仓库混合审计

- `D:\Godot\guild-workbench` 确实混合了 Godot 运行项目与旧网页工作台。
- Godot 范围：`project.godot`、`resources/`、`runtime/`、`systems/`、`tests/`。
- 旧工作台范围：`src/`、`index.html`、`package.json`、`package-lock.json`、`vite.config.ts`、`tsconfig.app.json`、`tsconfig.json`、`tsconfig.node.json`、`guild-project.v0.1.json`。
- `docs/` 与根目录 `README.md` 需要按内容决定是否迁移；它们不影响 Godot 运行。
- 当前仓库仍连接 `https://github.com/w7775p/guild-workbench.git`，不能作为新的纯 Godot 远端继续使用。
- 最短安全路径：保留旧目录不动，另建纯 Godot 目录，只迁移经过白名单确认的文件。
- 新目录名、新 GitHub 仓库名与可见性尚未确定；在用户确认前不创建、不提交、不推送。

## Godot 4.7 版本控制决策

- 官方稳定版文档明确要求忽略 `.godot/`，因为它只保存项目缓存数据。
- Godot 官方 4.4 UID 说明明确要求提交 `.uid` 文件；跨设备缺失 `.uid` 会破坏稳定资源引用并产生回退警告。
- 当前使用 Godot 4.7.2，因此纯 Godot 新仓库采用：忽略 `.godot/`，保留并提交 `*.uid`。
- 官方资料：`https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html`
- 官方资料：`https://godotengine.org/article/uid-changes-coming-to-godot-4-4/`

## 纯 Godot 新仓库白名单

- 现有 `README.md` 完全描述 Node/Vite 工作台，不能迁移，应重写为 Godot 项目说明。
- `docs/source-coverage.md` 与 `docs/test-report.md` 属于旧工作台资料，不影响 Godot 运行，不迁移。
- `resources/`、`runtime/`、`systems/` 中现有脚本是早期未验收占位骨架，且缺少中文注释；为保持 Task 1–11 的真实待执行状态，不迁移。
- 已验收并应迁移：`project.godot`、`tests/vertical_slice_test.tscn`、`tests/vertical_slice_test.gd`、`tests/vertical_slice_test.gd.uid`。
- 新建：`.gitignore`（忽略 `.godot/`、`*.translation`）、`.gitattributes`（统一 LF）、`AGENTS.md`、Godot 专用 `README.md`。
- 推荐新名称：本地 `D:\Godot\guild-today-godot`，远端 `w7775p/guild-today-godot`。

## 唯一项目目录落地结果

- Jackie 指定唯一活跃项目目录：`D:\Godot\guild_today`。
- 该目录原本是 Godot 4.7 新项目，保留了 `.editorconfig`、图标、图标导入配置、窗口和渲染设置。
- 最终非缓存文件：`.editorconfig`、`.gitattributes`、`.gitignore`、`AGENTS.md`、`icon.svg`、`icon.svg.import`、`project.godot`、`README.md`、`tests/vertical_slice_test.gd`、对应 `.uid` 与 `.tscn`。
- 旧工作台文件扫描结果：无 `src/`、Node/Vite/TypeScript 配置、工作台 JSON 或工作台文档。
- 敏感信息高置信模式扫描：无命中。
- 中文注释检查：`tests/vertical_slice_test.gd` 通过。
- Godot 4.7.2 无界面导入退出码 0；无界面运行退出码 0；实际输出 `Guild Today Open As Usual boot success`。
- 导入时因 `--quit-after 3` 主动结束编辑器，出现一次扫描线程终止警告；运行阶段无错误，不影响验收。
- 新目录已初始化本地 Git，初始提交为 `697ff0d7645f88019122cf4f72afb33fdada122d`。
- Jackie 已指定并实际使用 GitHub Desktop 发布私有仓库 `w7775p/guild_today`。
- 新增协作约束：遇到多种工具或执行路径时，先向 Jackie 确认最短路径，确认后只走该路径。
- GitHub Desktop 显示 `push complete`；只读核对确认 `main...origin/main`，远端为 `https://github.com/w7775p/guild_today.git`。
- 当前提交：`86d1d94 Update AGENTS.md`、`697ff0d chore: 初始化纯 Godot 项目`。

## Task 1：CharacterAsset 验收结论

- `CharacterAsset` 仅保存角色静态定义；运行时伤势、疲劳、关系与派遣事实继续留给后续层。
- TEST_ONLY 资源位于 `tests/fixtures/character_a.tres`，稳定 ID 为 `test_character_a`。
- 手写 `.tres` 仅声明 `ext_resource` 还不够，`[resource]` 必须显式写入 `script = ExtResource(...)`，否则加载结果只是普通 `Resource`，无法转换成 `CharacterAsset`。
- Godot 4.7.2 已实际加载该 fixture 并读出名称“角色A”和 `investigation = 10`；Task 1 可标记完成。

## 2026-08-29 V3 Task 1 首轮正式内容资产发现

- Notion 当前角色池明确列出六名首轮角色及稳定 ID；当前项目真源的概述仍写“五名正式角色”，数量冲突保留为 `【占位占位】`，本 Task 按角色池六人建立资源。
- 正式角色最小字段采用 `id`、`name`、`profession`、`battle`、`investigation`、`negotiation`；阿斯特里德职业在 Notion 中仍为暂定内容，因此资源写入 `【占位占位】`。
- 正式任务最小字段采用 `id`、`title`、`commissioner`、`description`、`objective`、`promised_reward`、`duration_days`、`min_party_size`、`max_party_size`、`repeatable`、`result_group`；`repeatable = false` 是依据“单次唯一测试任务”的工作性推测。
- `TaskAsset → ResultGroupAsset → ResultAsset[]` 已由正式 `.tres` 稳定引用串起；五个 ResultAsset 的 `report_text` 统一写入 `【占位占位】`。
- Task 1 只建立资产与引用，不提前写入结果条件和效果；Task 2、Task 3 负责真实判定与后果落地。
- 手写 `.tres` 继续遵循 `[gd_resource] → [ext_resource] → [resource]` 顺序，避免资源前向引用陷阱。
- Task 1 专项测试成功覆盖六名角色、任务核心字段、结果组 ID、五个结果 ID 和占位报告文本；V2 `runtime_chain_test.tscn` 回归成功。
- 本 Task 的占位内容：阿斯特里德职业、五个报告文本、结果条件、结果效果、任务终态、伤势目标与等级、关系/声望变化和后续救援 ID。
- 本 Task 的数值推测：延迟报酬 60、完整成功评价 `+5`、搜索失败信任 `-5`、伤势等级 1；这些数值尚未进入正式 ResultEffect 资源，后续日志必须继续标注推测来源。

## 2026-08-29 V3 Task 2 真实队伍能力判定发现

- `TaskResolutionSystem` 原先把三项能力求和并只把调查总值传给条件；当前已改为从 `DispatchInstance.character_refs[]` 即时读取三项最高值。
- 条件资源继续接收单个整数以保留 V2 直接调用兼容性；`ability_id` 由 `TaskResolutionSystem` 选择对应最高值，避免扩大为通用规则语言。
- 正式结果的混合条件必须以 `ConditionResource` 基类数组保存；若声明为某个具体子类数组，Godot 4.7.2 加载时会拒绝其他条件对象。
- 五结果当前按 V3 计划工作规则形成互斥区间，专项测试 11 组派遣全部唯一命中；V2 完整链保持通过。
- 本轮占位项：结果报告、结果效果、关系/声望具体变化、伤势目标与等级、查明位置终态、后续救援稳定 ID，以及 Task 3 的状态归属确认。
- 本轮数值推测：调查阈值 5、7，战斗阈值 4、6，以及由其构成的 5–6、4–5 区间；这些数字来自 V3 工作计划，仍需 Jackie 确认后才能作为正式策划。
- Task 3 已标记为 `[!]`：推进结果后果需要精确效果数值、终态/后续稳定 ID和伤势、关系/情报状态拥有者；继续编码会把未确认策划写成程序规则。
