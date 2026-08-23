# 《今日公会照常营业》Godot Agent 入口

## 项目范围

- 唯一项目目录：`D:\Godot\guild_today`。
- 禁止操作旧目录：`D:\Godot\guild-workbench`。
- 仓库只存放 Godot 运行项目及必要项目文档。
- `Resource` 表示静态定义，`Runtime / Instance` 表示已发生事实，`System` 管理运行逻辑。

## 当前阶段

- 项目处于第一阶段 Godot 运行时骨架建设。
- Task 状态以仓库根目录的 `task_plan.md` 为唯一动态真源；文件存在不等于任务完成。
- 历史 DOC-1～DOC-5 已完成；当前开发计划与进度以仓库根目录的三个规划文件为准。

## 开工读取路由

1. 读取本文件，确认项目路径、权限闸门和当前阶段。
2. 读取 `docs/project/workflow.md`，确认协作流程和决策优先级。
3. 修改架构、Resource、Runtime 或 System 时，读取 `docs/project/architecture.md` 与 `docs/project/engineering_rules.md`。
4. 遇到错误、回归或资源文件问题时，读取 `docs/project/known_traps.md`。
5. 读取仓库根目录的 `task_plan.md`、`progress.md`、`findings.md`，确认当前任务与历史决策。

## 决策与执行闸门

- 用户明确要求优先；项目真源架构约束高于临时实现偏好。
- 每次只执行一个已授权 Task 或 DOC，不提前实现后续任务。
- 遇到多种工具或路径时，先确认最短路径，再只走已确认路径。
- 占位文件、空壳类和静态检查不能标记完成；必须满足对应验收条件。
- 每次完成后报告：做了什么、没做什么、验证结果、下一步建议。

## 代码与仓库闸门

- 所有新增或修改代码必须带简明中文注释，解释意图、边界或关键流程。
- `.godot/` 为本地缓存；`*.uid` 为稳定资源标识，按工程规则处理。
- 未获 Jackie 明确授权，不得 `git commit`、`git push`、合并、强推或删除分支。
- 文档任务不得修改 Godot 代码、资源、场景或 `project.godot`。

## 完成报告

- 只报告当前任务的实际范围，不把文件存在描述成能力完成。
- 发现阻塞时记录真实错误和替代方案，不静默重试。
- 下一步只建议一个最靠前的未完成任务。
