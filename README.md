# 《今日公会照常营业》

Godot 4.7.2 运行项目，当前目标是完成 V3 首张真实任务的可玩循环。

## 当前阶段

- V2 Task 0–16 已完成。
- V3 Task 1 已建立六名正式角色、首张任务与五个结果资产。
- V3 Task 2 已完成真实队伍最高能力判定。
- V3 Task 3 已完成结果后果持久化与报告记录。
- V3 Task 4 已完成最小日期与任务生命周期。
- V3 Task 5 已完成正式 GameSession。
- V3 Task 6 已完成核心循环 UI；Task 7 等待授权。

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
├── assets/types/
├── assets/data/
├── runtime/
├── tests/
└── docs/project/
```

## 任务规划

- [任务计划](task_plan.md)：V3 Task 1–8 当前执行真源。
- [进度日志](progress.md)：每次任务的实际变更与验证。
- [发现记录](findings.md)：架构决策、陷阱和长期发现。
