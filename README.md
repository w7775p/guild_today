# 《今日公会照常营业》

Godot 4.7.2 运行项目，目标是逐步验证第一阶段运行时骨架。

## 当前阶段

- 已完成 Task 0：项目入口与最小启动场景。
- 已完成 Task 1：`CharacterAsset` 静态资源加载。
- 已完成 Task 2：`TaskAsset` 静态资源加载。
- 后续 Task 必须按 `task_plan.md` 的授权和验收状态推进。

## 启动项目

使用 Godot 4.7.2 打开 `D:\Godot\guild_today\project.godot`，按 `F5` 运行主场景。

当前测试入口会在 Output 输出启动信息和已验收资源的加载结果。

## 文档地图

- [Agent 入口](AGENTS.md)：AI 读取路由、执行闸门和项目边界。
- [运行架构](docs/project/architecture.md)：Resource、Instance、System 与 MVP 运行链。
- [工程规则](docs/project/engineering_rules.md)：代码组织、资源规则、验证和 Git 纪律。
- [协作流程](docs/project/workflow.md)：人与 AI 的开发流程、决策优先级和汇报方式。
- [已知陷阱](docs/project/known_traps.md)：Godot、资源、状态边界和回归问题记录。

## 目录概览

```text
res://
├── project.godot
├── resources/
├── tests/
└── docs/project/
```

## 任务规划

- [任务计划](task_plan.md)：Task 0–16 当前执行真源。
- [进度日志](progress.md)：每次任务的实际变更与验证。
- [发现记录](findings.md)：架构决策、陷阱和长期发现。
