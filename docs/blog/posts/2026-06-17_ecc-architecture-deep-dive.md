---
date: 2026-06-17
tags: [ECC, Agent, 多回路系统, VSM, 编排, 自进化, Harness Engineering]
summary: "ECC 是跨 harness 的 agent 操作系统，67 个 agent + 271 个 skill + 92 个命令。深度拆解后发现它已经是完整的 VSM 实现，支持四种 loop 模式、Kanban 协作、两道人工闸门、/evolve 自进化。但编排仍是规则驱动，自进化方向仍需人引导。"
---

# ECC 深度解析：一个已经跑起来的多回路 Agent 系统

前面三篇讨论了 Loop Engineering 的概念、控制论根基、落地现状。这一篇看一个具体实现——ECC（Everything Claude Code），一个跨 harness 的 agent 操作系统。

---

## 我的观察

### ECC 是什么

ECC 自己的定位是"agent harness operating system"——不是某个 agent 的插件，是 agent 的操作系统。支持 Codex、Claude Code、Cursor、OpenCode、Gemini、Zed、GitHub Copilot 等 8+ 个平台。

规模：67 个专业 agent、271 个 skill、92 个命令。

### 67 个 Agent 不是扁平的

agent 按职能分了明确的层：

| 职能层 | 代表 agent | 角色 |
|--------|-----------|------|
| 规划层 | planner、architect、chief-of-staff | 拆任务、做设计、管沟通 |
| 执行层 | code-reviewer、tdd-guide、e2e-runner | 写代码、跑测试 |
| 专项层 | python-reviewer、rust-reviewer、database-reviewer | 按语言/领域分工 |
| 修复层 | build-error-resolver（各语言变体） | 专治编译错误 |
| 运维层 | loop-operator、harness-optimizer、security-reviewer | 管循环、管调校、管安全 |
| 特殊层 | chief-of-staff、marketing-agent | 非代码任务 |

每个 agent 的 .md 配置文件定义了：职责、可用工具、适用模型。这就是"人搭团队"——团队成员是人提前定义好的。

### 编排分三层，不是简单的 if-then

ECC 的编排比我之前以为的要精细：

**第一层：orch-pipeline（统一编排引擎）**

所有 `orch-*` 技能共享一个底层引擎。流程：Research → Plan → TDD → Review → Commit。根据任务大小自动裁剪——trivial 任务直接跳到 TDD，large 任务跑全流水线。

两道人工闸门：Plan 完成后人审批任务清单，Commit 前人确认 diff。人不介入中间执行，但在关键节点保留控制权。

**第二层：场景化封装**

| 技能 | 场景 | 特殊逻辑 |
|------|------|---------|
| orch-add-feature | 新功能 | 完整流水线 |
| orch-fix-defect | 修 bug | 第一步必须先写失败的回归测试 |
| orch-change-feature | 改功能 | 先分析影响范围 |
| orch-refine-code | 重构 | 不改行为只改结构 |
| orch-build-mvp | 从零搭项目 | 先搜骨架项目再迭代 |

**第三层：plan-orchestrate（计划→命令生成器）**

这个最特别——它不执行编排，只生成编排命令。读一个计划文档，拆成步骤，输出可粘贴的 `/orchestrate custom` 命令。人审查后才执行。

### 四种 Loop 模式

按复杂度递增：

| 模式 | 机制 | 适合场景 |
|------|------|---------|
| Sequential Pipeline | `claude -p` 串行跑 | 简单流水线 |
| Infinite Agentic Loop | 无限循环直到人停 | 持续改进 |
| Continuous PR Loop | 持续监听 PR → 修复 → 提交 | CI/CD 守护 |
| RFC-Driven DAG | RFC 拆任务 → 多 agent 并行 → 合并队列 | 大型项目 |

loop-operator 是循环的守护者：要求质量门、eval 基线、回滚路径。当 checkpoint 无进展、重复失败、成本漂移、阻塞性合并冲突时自动升级。

### 多 Agent 协作：Kanban 模式

team-agent-orchestration 定义了具体机制：

每个 agent 有明确合约：owner（谁干）、scope（干多大）、state（当前状态）、evidence（产出证据）、merge gate（合并条件）。

一个控制面板可视化：active work / blockers / merge readiness。

反模式警告很实际：Agent Soup（没有 owner）、Invisible Work（干了活但不可见）、Overlapping Parallel Writes（多人改同一文件）。

### 自进化：`/evolve` 命令

agent 在执行过程中积累的行为模式（instincts），通过 `/evolve` 自动聚类成更高层结构：

- **commands**：用户主动调用的动作
- **skills**：自动触发的行为
- **agents**：复杂的多步流程

这就是"个体进化"的工程实现——agent 从经验中提炼出新能力。

### 两个明确的边界

**编排是规则驱动的**——orch-pipeline 是预设流程，不是主 agent 现场推理。dynamic-workflow-mode 允许任务局部创建 harness，但也是模板化的。

**自进化方向没有高层引导**——/evolve 能把行为模式聚类成新 skill，但不知道"该长什么能力"。进化方向还是需要人判断。

---

## AI 锐评

### ECC 是目前最接近完整 VSM 实现的开源项目

S1（67 个 agent）→ S2（Kanban 协调）→ S3（orch-pipeline + 闸门）→ S4（MCP + chief-of-staff）→ S5（人审批），五层全有对应。反馈回路全通。这不是概念设计，是已经在跑的工程系统。

### 两道人工闸门的设计是精妙的平衡

Gate 1 审计划、Gate 2 审结果，中间不介入。这恰好是我们讨论的"人从 loop 内部退到外部"的工程实现——人不参与执行，但在入口和出口保留控制权。比完全自主安全，比全程介入高效。

### plan-orchestrate 是被低估的设计

它不执行编排，只生成编排命令让人审查。这解决了一个关键信任问题：你不需要信任 agent 的编排决策，因为它只是"建议"，你执行前可以改。这比直接让 agent 自主编排务实得多。

### `/evolve` 和"有方向的进化"之间还差一步

/evolve 能从经验中长出新能力，但不知道该长什么。如果把 /evolve 跟 /goal 结合——goal 定义"我需要什么能力"，evolve 在这个方向上进化——就接近了我们讨论的"有约束的适应"。目前这一步还没有人做。
