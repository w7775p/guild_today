# 《公会》正式工程铁律

> 本页来源（正式工程铁律）：https://app.notion.com/p/3c07fb71ada4813eb79dcfda505d78a6?pvs=204
> 同步时间：2026-08-18T06:51:50.592Z
> 职责：代码组织、数据与状态所有权、验证流程和 Git 纪律。
## 一、工程铁律
<table fit-page-width="true" header-row="true">
<tr>
<td>#</td>
<td>铁律</td>
<td>执行约束</td>
</tr>
<tr>
<td>1</td>
<td>最小路径</td>
<td>只实现当前闭环需要的功能；禁止为未来需求提前抽象、预建系统或扩大 Schema。</td>
</tr>
<tr>
<td>2</td>
<td>禁止猜测与无意义兜底</td>
<td>接口、字段、生命周期不明确时先查真源和代码；不得用猜测字段、静默默认值或“保证能跑”的冗余分支掩盖未知。</td>
</tr>
<tr>
<td>3</td>
<td>单一真相源</td>
<td>同一运行事实只允许一个拥有者。派生值实时计算；不得维护可独立修改的副本。</td>
</tr>
<tr>
<td>4</td>
<td>系统独占写入权</td>
<td>`GuildState`、`TaskSystem`、`DispatchSystem`、`StateRelationshipSystem`、`ReportIntelSystem` 等只修改自己拥有的状态；其他系统通过公开 API 请求变更。</td>
</tr>
<tr>
<td>5</td>
<td>API 发命令，Signal 通知事实</td>
<td>业务操作使用明确方法调用；Signal 表示“某事实已经变化”。禁止用 Signal 作为隐式命令总线，也禁止跨系统直接改内部字段。</td>
</tr>
<tr>
<td>6</td>
<td>静态 Resource 运行时只读</td>
<td>`CharacterAsset / TaskAsset / EventAsset / ResultGroupAsset / ResultAsset` 等静态定义运行时不得写回。单局变化必须进入运行时事实或对应系统。</td>
</tr>
<tr>
<td>7</td>
<td>ID 是稳定契约</td>
<td>跨资产和运行实例通过稳定 ID / 明确引用关联。修改 ID 必须全局检查所有引用；禁止根据显示名称建立业务关联。</td>
</tr>
<tr>
<td>8</td>
<td>TEST_ONLY 严格隔离</td>
<td>测试资产统一 `test_` 前缀并放在测试目录；可使用临时确定性 fixture，但不得自动升级为正式策划 Schema，也不得让正式构建依赖测试内容。</td>
</tr>
<tr>
<td>9</td>
<td>确定性优先</td>
<td>第一阶段自动测试与 fixture 禁止随机。未来引入随机后，预览与实际结算必须共享同一次已确定结果，不允许各自重抽。</td>
</tr>
<tr>
<td>10</td>
<td>显式生命周期</td>
<td>Task / Dispatch 等实例的状态只能由拥有它的 System 通过公开方法迁移。关键清理必须显式执行，不依赖 `_exit_tree()`、析构或 UI 关闭副作用。</td>
</tr>
<tr>
<td>11</td>
<td>UI 不拥有业务状态</td>
<td>UI 只读取、展示和提交请求；不得直接修改 Guild / Task / Dispatch / Character 等运行事实。</td>
</tr>
<tr>
<td>12</td>
<td>改动前追链路</td>
<td>修改公开方法、ID、Signal、Resource 字段、生命周期或系统职责前，先确认调用方、消费方和数据生产链。</td>
</tr>
<tr>
<td>13</td>
<td>改动后必须验证</td>
<td>新增或修改 `.gd` 后执行对应单文件 parse/check；再运行相关自动测试。重命名后搜索旧名残留，并检查 `git diff`。</td>
</tr>
<tr>
<td>14</td>
<td>Autoload 边界</td>
<td>Autoload 全局名不得与 `class_name` 冲突。新增 Autoload 必须验证 `project.godot` 注册及初始化依赖。</td>
</tr>
<tr>
<td>15</td>
<td>Git 写入纪律</td>
<td>未经用户明确指令不得 push。提交前必须确认改动范围，不把无关文件混入提交。</td>
</tr>
</table>
## 二、命名与目录约束
<table fit-page-width="true" header-row="true">
<tr>
<td>对象</td>
<td>规范</td>
</tr>
<tr>
<td>文件 / 目录</td>
<td>`snake_case`</td>
</tr>
<tr>
<td>类名</td>
<td>`PascalCase`</td>
</tr>
<tr>
<td>常量</td>
<td>`CONSTANT_CASE`</td>
</tr>
<tr>
<td>测试资产 ID</td>
<td>统一 `test_` 前缀</td>
</tr>
<tr>
<td>正式稳定 ID</td>
<td>英文、稳定、唯一；不随显示名称修改</td>
</tr>
<tr>
<td>禁止命名</td>
<td>中文文件名、空格、`_final`、`_new`、`_copy`、`_v2` 等临时版本名</td>
</tr>
</table>
## 三、数据生产链约束
当前策划生产链仍为：
```plain text
本地原稿 / Excel → Python → 完整策划资产 JSON → 工作台 → Godot
```
- 源数据与生成物必须分离；禁止直接修改由上游生成的正式产物来绕过源头。
- 新增或修改字段时必须检查“源字段 → 转换 → 输出 → Godot 加载 / 消费”完整链路。
- Godot Importer 与正式 Runtime Schema 未冻结前，不得让 TEST_ONLY fixture 反向定义正式 JSON 契约。
## 四、每次实现的最低完成标准
1. 与当前真源和已冻结架构一致。
2. 没有新增第二真相源。
3. 没有越权写入其他系统状态。
4. 相关脚本通过 parse/check 与自动测试。
5. 重命名、ID、Signal、公开 API 无残留旧引用。
6. 对照 https://app.notion.com/p/3c07fb71ada4819391eaefbecabc326e 完成同类陷阱自查。
7. `git diff` 只包含本次必要改动。


## 附录 A：TEST_ONLY 测试资产边界
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

## 附录 B：TEST_ONLY 工程边界
- ID 统一 `test_` 前缀。
- 放入 `tests/fixtures/`。
- 第一阶段判定保持确定性。
- 正式运行路径可以消费 fixture，但不得为 fixture 另建第二套业务流程。
- fixture 字段不得自动升级为正式策划或 Runtime Schema。

## 附录 C：Git 操作纪律
- 未经用户明确指令：**禁止 push**。
- 提交前确认 scope，不混入无关文件。

