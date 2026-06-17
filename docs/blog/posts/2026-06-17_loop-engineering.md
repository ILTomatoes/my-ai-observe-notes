---
date: 2026-06-17
tags: [AI工程, Agent, Loop Engineering, 自动化, Qoder]
summary: "Loop Engineering 主张让 agent 自己跑完感知→判断→行动→反馈的循环，人只定规则和验收结果。从 CI+AI 到 CI in AI，再到 automate workflow in AI，是同一趋势的三层递进。"
---

# 从 Prompt Engineering 到 Loop Engineering：人从循环里退出来了

AI 工程的概念迭代很快。半年前聊 Prompt Engineering，接着 Context Engineering，然后 Harness Engineering，2026 年 6 月又来了个 Loop Engineering。

核心就一件事：agent 跑代码、调工具、看报错、改文件、跑测试、再决定下一步——这个循环应该由 agent 自己跑完，人只负责定义规则和验收最终结果。

## 我的观察

### 五块拼图

Loop Engineering 的系统由五部分构成，每块解决一个问题：

| 模块 | 职责 |
|------|------|
| 调度 | 什么时候开始、什么时候停 |
| 知识 | 怎么干活 |
| 连接 | 能触达哪些系统 |
| 协作 | 谁执行谁验证 |
| 记忆 | 下次从哪接着 |

Qoder CLI 里的落地方式：`/loop` 定时触发，`/goal` 定义退出条件，Skills 当执行手册，MCP Server 接外部系统（GitHub/Slux/Linear/数据库），Subagent 做 Maker/Checker 分离——写代码和审代码是不同 agent。

### 我的递进：CI + AI → CI in AI → Automate Workflow in AI

我最初设想的基于 AI 的自动化工作流是 CI + AI——AI 辅助 CI 环节里的某些步骤（写代码、review）。Loop Engineering 更进一步：CI 本身成了 AI 循环的一部分，agent 自己跑测试、提 PR、通知团队。

不只是 CI in AI，更准确的说法是 **automate workflow in AI**——整个自动化工作流（CI + 部署 + 监控 + 通知 + 工单）都变成 agent 循环的内部环节。人从"在循环里每一步都推"变成"在入口定规则、在出口验收结果"。

### 代价也很诚实

文章没回避问题：安全边界（生产发布、支付逻辑必须禁区）、token 成本（30 分钟间隔一天 48 轮）、理解债（agent 跑得快人容易跟不上改了什么）。

---

## AI 锐评

### 你的"三层递进"比原文更锐利

原文说的是"人从 loop 内部退到外部"——描述的是**人的位置变化**。你说的是**系统归属**的变化：自动化工作流从"AI 辅助的外部系统"变成"AI 内部的子系统"。这个视角更本质。位置变化是表象，归属变化才是范式转移。

### 五块拼图跟 Hermes Agent 完全同构

这不是 Qoder 独创——Hermes Agent 的 cronjob 对应调度，skills 对应知识，MCP 对应连接，delegate_task 对应协作，memory + session_search 对应记忆。任何设计得足够完整的 agent 系统都会收敛到这五块。说明这不是某个产品的特性，而是**自主 agent 的必要条件**。

### Automate workflow in AI 的边界在哪？

当 loop 涉及的不只是代码（写周报、发邮件、改飞书表格、生成 PPT），"automate workflow in AI"就从"AI 编程范式"扩展成"AI 工作范式"。这个扩展是自然发生的还是需要另外一套框架？我认为是自然的——五块拼图的抽象层足够通用，不依赖"代码"这个具体场景。真正的问题是：**不同场景的安全边界怎么画？** 写代码可以 git revert，发错邮件可没有 undo。
