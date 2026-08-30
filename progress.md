# 进度摘要

## 当前目标

把 V2 已验证的 Godot 运行时骨架推进为可人工操作、可判断、可产生持续后果的 V3 真实游戏循环。

主链：阅读委托与角色 → 选择队伍 → 派遣 → 等待两日 → 唯一结果 → 结算后果 → 阅读报告。

## 核心约束

- 项目目录：`D:\Godot\guild_today`；禁止操作 `D:\Godot\guild-workbench`。
- Godot 4.7.2 可执行文件：`D:\steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`；验证时直接使用绝对路径。
- V3 只按 Task 1→8 顺序推进，一次只做一个 Task。
- 未确定文本和 ID 使用“类型＋语义”的唯一占位符；推测数值必须单列，不能伪装成正式策划。
- 每个 Task 必须完成 Godot 4.7.2 单脚本检查、专项测试、受影响回归、旧引用搜索、`git diff --check` 与差异审计。
- Task 完成后只创建一个本地 commit；禁止 push、合并、强推、改写历史、删除分支。
- 新增或修改 GDScript 必须带简明中文注释。

## 已完成

### V2 基线

- V2 Task 0–16 已完成；独立 `tests/runtime_chain_test.tscn` 通过，作为后续回归基线。
- 已验证链路：`TaskAsset → TaskInstance → DispatchInstance → TaskResolutionSystem → ResultGroupAsset → ResultAsset → ResultInstance → ResultSettlementSystem → GuildState → ReportIntelSystem`。
- 关键证据：`gold=100`、`total_reputation=5`，报告链成功，派遣结束后角色释放。

### V3 Task 1

- 本地 commit：`6fb04df`。
- 六名角色、首张任务 `task_missing_caravan`、结果组 `result_group_missing_caravan`、五个 ResultAsset 已建立并互相引用。
- Task 1 专项测试、V2 回归和 Godot 4.7.2 单脚本检查通过。

### V3 Task 2

- 本地 commit：`78f4e37`。
- `TaskResolutionSystem` 从 `DispatchInstance.character_refs[]` 即时读取队伍最高战斗、调查、交涉能力。
- `AbilityCondition` / `AbilityBelowCondition` 使用 `ability_id`，五结果形成互斥区间。
- Task 2 矩阵 11 组、Task 1 专项回归、V2 回归和 Godot 4.7.2 单脚本检查通过。

### V3 Task 3

- 五个正式结果已分别写入金币、关系、伤势、情报、后续任务占位与任务终态占位，并生成可按派遣 ID 读取的报告记录。
- 未冻结文本和 ID 已改为唯一语义占位符；阿斯特里德职业及 Task 1 回归预期统一为“魔剑士”。
- 13 个相关脚本通过 Godot 4.7.2 单脚本检查；Task 3 专项、Task 1/2 回归与 V2 `runtime_chain` 回归退出码均为 0。
- Task 3 专项中的重复结算 ERROR 属于独立负向分支，五个结果均验证重复写入被拒绝。

### V3 Task 4

- 本地完成提交：`feat(v3): 实现最小日期与任务生命周期`。
- 新增 `runtime/time/day_system.gd`，以整数游戏日推进并发出日期变化通知。
- `DispatchInstance` 记录 `started_day`、`due_day`、`ended_day`；`DispatchSystem` 提供到期查询和显式结束，角色占用持续到结束。
- `ResultSettlementSystem` 拒绝定时派遣在缺少当前日期或尚未达到 `due_day` 时结算。
- Task 4 专项测试覆盖第 1 日派遣、第 2 日未到期、第 3 日到期、到期前结算拒绝、显式结束和角色释放。
- Task 4 专项、Task 1/2/3 回归与 V2 `runtime_chain` 回归退出码均为 0；到期前结算拒绝属于预期负向分支。

### V3 Task 5

- 本地完成提交：`feat(v3): 组装正式游戏会话`。
- 新增 `runtime/game_session.gd` 与正式场景，统一编排 Task、Dispatch、Day、Resolution、Settlement、状态和报告系统。
- 正式会话只加载六名正式角色与 `task_missing_caravan`，公开查询、派遣、推进日期、ACTIVE 派遣和未读报告接口。
- Task 5 专项覆盖完整成功、查明位置、搜索失败三条端到端路线；均在第 3 日完成唯一结果、结算、报告与角色释放，业务错误输出为 0，Godot 环境告警另列。
- 修改脚本单文件检查、Task 5 专项、Task 3/4 与 V2 `runtime_chain` 回归退出码均为 0。

### V3 Task 6

- 本地完成提交：`feat(v3): 实现核心循环界面`。
- 新增公会主界面、任务文档、角色卡、派遣面板和报告界面；UI 只调用 GameSession 公开 API。
- 鼠标控件专项覆盖任务文件开关、0/1/2/3 人校验、角色选择、确认派遣、两次日期推进、报告打开与关闭。
- 报告展示结果事实、队伍最高能力判定依据与持续后果；ACTIVE 角色不可选择，结算后恢复可派遣。
- `project.godot` 主场景已切换为 `ui/main/guild_main.tscn`，正式窗口为 1280×800。
- 修改脚本单文件检查、Task 6 专项、正式主场景启动、Task 5 与 V2 `runtime_chain` 回归退出码均为 0；业务错误输出为 0，Godot 环境告警另列。

### V3 Task 7

- 已完成自动与人工验收：四条正式路线通过 `GameSession`，带伤救回通过临时普通 `CharacterAsset` 数值覆盖；Jackie 已确认三轮人工验收通过。
- Task 7 唯一本地完成提交：`de0fbb5`。
- 六名正式角色全部单人及双人派遣共 21 种组合中：完整成功 11 种、延迟成功 4 种、查明位置 3 种、搜索失败 3 种、带伤救回 0 种。
- Jackie 决定保留正式角色与结果条件；当正式角色能力数值无法覆盖某结果区间时，专项测试允许临时创建普通 `CharacterAsset` 覆盖该结果，该情况按数值覆盖缺口验收，不判定为角色设计缺陷。
- 已新增 `tests/fixtures/test_injured_rescue_character.tres` 与对应基础规则测试；同时补充 Task 7 完整专项测试，临时角色只用于数值覆盖，不进入正式运行路径。
- `tests/v3_task7_acceptance_test.tscn` 退出码为 0，输出 `formal_routes=4, temporary_numeric_fallback=true, lifecycle=true, persistent_effects=true`；Task 1–6、fixture 与 V2 `runtime_chain` 回归退出码均为 0，正式主场景启动退出码为 0。
- 专项负例中的“到期前结算/重复结算” ERROR 属于预期拒绝分支；Godot 运行环境仍报告 `user://logs/godot.log` 写入失败和根证书仓库读取告警，未出现游戏逻辑失败。

### V3 Task 8

- 已接入正式任务 `task_collapsed_mine_rescue`、结果组 `result_group_collapsed_mine_rescue` 与 8 个结果资产；条件使用三项能力阈值战斗 7、调查 6、交涉 8 的 AND 组合，结果分区互斥。
- `GameSession` 新增可配置正式任务资产路径，默认首张任务行为保持不变；人工入口为 `ui/main/collapsed_mine_guild_main.tscn`。
- `tests/v3_task8_collapsed_mine_test.tscn` 退出码为 0，输出 `results=8, formal_routes=8, unique_results=true, game_session=true`；正式主场景、Task 1–7 和 V2 `runtime_chain` 回归退出码均为 0。
- 专项验证仅出现 Godot 环境日志告警，未出现资源解析、结果零命中、多命中或业务链失败。
- Jackie 已确认第二张任务人工验收通过。

## 当前进度

- Task 1、Task 2、Task 3、Task 4、Task 5、Task 6、Task 7、Task 8 完成。
- Jackie 已解除 Task 3 前置阻塞，允许未定文本和 ID 使用唯一语义占位符，未定数值采用可替换的工作性推测。
- Task 7、Task 8 已完成自动与人工验收；V3 Task 1–8 已完成。

## V3 未冻结策划缺口（不等同于代码未实现）

- 五个结果的任务终态。
- 延迟成功的具体金币。
- 完整成功评价、搜索失败信任的数值、稳定状态 ID 与拥有者。
- 带伤救回的受伤角色选择规则与伤势等级。
- “查明位置”是否结束当前任务，以及后续救援稳定 ID。
- “带伤救回”要求调查能力至少 5 且战斗能力为 4–5，六名正式角色及其双人组合均无法满足；专项测试已使用临时普通 `CharacterAsset` 覆盖。
- 五份完整玩家可见报告文本。
- 正式策划的五人/六人角色数量冲突。
- 任务池“结果组待建立”与结果组池已有稳定 ID 的冲突。
- 情报由 `ReportIntelSystem` 持有，关系由 `StateRelationshipSystem` 持有；跨阶段最终契约仍待真实内容验证。

## 下一步行动

V3 Task 1–8 已完成并通过验收；Demo Readiness 审计修复完成后停止继续扩展，重新制定 V4 计划。

## 历史归档

旧版重复进度记录已移至用户输出归档 `C:\Users\lvy\Documents\Codex\2026-08-29\shi\outputs\context_archive_2026-08-30\progress_legacy.md`，需要追溯时再查阅。

## Demo Readiness 审计状态（2026-08-31）

- 第一轮并行审计已完成：架构/场景、数据契约、任务派遣/结算/测试均依据当前仓库给出路径和证据。
- 已实施低风险边界修复和真实失败退出码测试；新增 `tests/demo_readiness_audit_test.tscn`。
- 当前验证可覆盖正式资产加载、ID/引用完整性、非法字段、任务派遣、结果判定、资源结算、异常数据、生命周期和内存恢复。
- 第二轮复审已完成：47 个 GDScript 单文件检查通过，12 个 headless 测试场景和两个正式主场景退出码均为 0；正式 23 个 `.tres` 的 ID 重复数为 0，`git diff --check` 通过。
- `SaveSystem`、后续任务消费者、EventAsset、Importer、标准终态映射仍为 **NOT IMPLEMENTED / UNVERIFIED**，正式文案与 Task8 奖励仍待策划冻结。
- 当前审计提交只包含可安全确认的边界收紧与测试修复；无法由仓库证据确认的策划语义继续保留为 **UNVERIFIED**。
