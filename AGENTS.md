# 《今日公会照常营业》Godot 项目协作规则

## 项目范围

- 本仓库只存放 Godot 运行项目及其必要的项目文档。
- 禁止加入旧网页工作台、Node.js、Vite、TypeScript 或浏览器草稿数据。
- Resource 表示静态策划定义，Runtime / Instance 表示实际发生的游戏事实，System 管理运行逻辑。

## 项目真源

开工前按以下顺序读取本地工作镜像：

1. `docs/agents/godot_runtime_architecture.md`
2. `docs/agents/engineering_rules.md`
3. `docs/agents/notion_agents.md`
4. `docs/agents/known_traps.md`

Notion 页面仍是项目真源，本地文件用于 Agent 稳定访问、版本审查和离线工作。

## 开发规则

- 每次只执行 Jackie 明确授权的一个 Task，不提前实现后续 Task。
- 遇到多种工具或执行路径时，先询问 Jackie 并确认最短路径；未经确认不得自行堆叠替代方案。
- 所有新增或修改的代码必须带简明中文注释。
- 注释解释设计意图、边界或关键流程，禁止无意义逐行翻译代码。
- 占位文件、空壳类和静态检查不算完成；必须满足对应 Task 的运行验收条件。
- 每次完成后报告：这次做了什么、这次没做什么、验证结果、下一步建议。

## Git 规则

- `.godot/` 是本地缓存，不进入版本控制。
- `*.uid` 是 Godot 稳定资源标识，必须进入版本控制。
- `git commit` 和 `git push` 必须分别获得 Jackie 明确授权。
- 禁止自动合并、强推或删除远端分支。
