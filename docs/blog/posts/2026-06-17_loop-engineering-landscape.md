---
date: 2026-06-17
tags: [Loop Engineering, Agent, 落地实践, 工具生态, Claude Code, ECC, Anthropic]
summary: "多方资料汇总：Loop Engineering 不再是概念，已经有六原语共识、真实工具链、Anthropic 内部数据验证。但编排仍是规则驱动而非自主规划，审查带宽是最大瓶颈。"
---

# Loop Engineering 落地现状：大家都在怎么搞

前两篇分别聊了 Loop Engineering 的概念和它的控制论根基。这一篇看落地——搜了一圈中文社区的讨论，汇总一下别人怎么理解、怎么实现、踩了什么坑。

---

## 我的观察

### 概念层级：Loop 不是终点

多数文章收敛到的演进路线：

```
Prompt Engineering → Context Engineering → Harness Engineering → Loop Engineering → Factory Model
```

每一代都在做同一件事：把人从更底层的执行中抽出来。Loop Engineering 把人从"每一轮对话"中抽出，Factory Model 据说要把人从"写 loop"中抽出——但目前还是个概念，没有成熟实现。

### 六原语：比五块拼图多了一块

原文说五块拼图（调度、知识、连接、协作、记忆），社区讨论收敛到六个：

| 原语 | 对应 | 新增的关键点 |
|------|------|------------|
| Automations | 调度 | /loop、/goal、CronCreate |
| **Worktrees** | **并行隔离** | Git worktree，多个 agent 改同一仓库不冲突 |
| Skills | 知识 | SKILL.md，把意图固化到磁盘 |
| Connectors | 连接 | MCP，接 GitHub/Slack/Linear |
| Sub-agents | 协作 | 写代码和审代码分开 |
| State | 记忆 | progress.md、git log、外部看板 |

多出来的 **Worktrees** 是我们之前讨论没提到的。并行隔离是工程落地时必须解决的——两个 agent 同时改同一个文件，不隔离就会互相覆盖。

### 编排机制：规则驱动，不是自主规划

搜了一圈，目前所有主流实现的编排都是**人写好规则，agent 按规则执行**：

```
Claude Code：  skill 里写好"代码改了→调 code-reviewer"
Codex：       .codex/agents/ TOML 配置触发条件
ECC：         67 个 agent 的调用规则写在 orchestration 逻辑里
Qoder：       Quest 模式预设任务模板
```

刘道玉那篇文章给了一个真实的 loop 流程：

```
Automation 每天运行 
→ 调用 triage skill（预设） 
→ 写 progress.md（预设） 
→ 派 sub-agent 实现（预设） 
→ sub-agent 审查（预设） 
→ 开 PR 
→ /goal 判断终止
```

每一步都是 skill 里写好的逻辑，不是主 agent 现场推理"该调谁"。**主 agent 自主规划分派是下一步，目前没有成熟实现。**

### Anthropic 内部数据

2026 年 5 月的数据：

- **>80% 代码由 Claude 编写**
- 工程师日均代码合并量增长 **8 倍**
- 开放式任务成功率 **76%**

Claude Code 之父 Boris Cherny 现在的工作就是写 Loop，不再直接写代码。内部经历了两次认知转变：不写代码让 Agent 写 → 不 prompt Agent 让 Loop prompt Agent。

### 三高度模型

| 高度 | 做什么 | 人在哪 |
|------|--------|--------|
| 低 | 手写代码 + AI 补全 | 人在 loop 里推每一步 |
| 中 | 并行多 Agent 会话 | 人在入口触发、出口验收 |
| 高 | 编写 Loop 替你 prompt Agent | 人只写 loop 本身 |

第三层的意思是：你写的不再是代码，也不是 prompt，而是 **loop 的定义**——什么时间触发、调用哪些 agent、什么条件停、异常怎么上报。Loop 本身就是你的"程序"。

### 真正的瓶颈：审查带宽

工具不是瓶颈。**人的审查能力才是。**

你可以同时跑 5 个 agent，但如果你一小时只能审 1 个 PR，其他 4 个就在烧 token 等你。这就是"编排税"——agent 跑得越快，人审不过来，理解债越积越大。

解法方向：reviewer agent 自动化（AI 审 AI），但目前没有谁能完全替代人的判断。

### 人才市场信号

已经出现专门的 LoopEngineer.ai 平台，薪资 $150k-$300k+。岗位定义是：设计、构建和维护 AI agent 的自主循环系统。说明市场已经开始认这个方向。

### 工具生态

| 工具 | 定位 | Loop 支持方式 |
|------|------|-------------|
| Claude Code | Anthropic 的 agent 编码工具 | /loop、/goal、hooks、SKILL.md |
| Codex（OpenAI） | OpenAI 的 agent 编码工具 | Automations、.codex/agents/ TOML |
| Qoder（阿里） | 智能体编程平台 | Quest 模式、CLI |
| ECC | 跨 harness 的 agent 操作系统 | 67 agent + 271 skill + loop-operator |
| OpenClaw | 开源 agent 框架 | Skills + heartbeat + 子 agent |
| LangGraph / CrewAI / AutoGen | 编排框架 | 框架层面支持循环 |

ECC 的定位最特别——它不是某个 agent 的插件，而是**跨 harness 的操作系统**，同时支持 Codex、Claude Code、Cursor、OpenCode、Gemini 等 8+ 个 agent 平台。

---

## AI 锐评

### Loop Engineering 已经过了"概念期"，进入"工程期"

从搜到的材料看，社区讨论已经不停留在"什么是 Loop Engineering"，而是在聊"怎么落地"、"token 成本怎么控"、"审查带宽怎么解决"。Anthropic 的内部数据（80% 代码由 Claude 写、合并量 8 倍增长）说明这不是 PPT 里的东西，是已经在跑的工程实践。

### 规则驱动编排是务实选择，但限制了上限

目前所有工具都用规则驱动编排，不是因为大家不想做自主规划，而是自主规划的可靠性还不够。一个 agent 连"该调谁"都要自己推理，出错概率比预设规则高得多。但这也意味着系统的上限被规则的完备性锁死了——你预设不到的场景，系统就处理不了。

### 审查带宽问题会成为 Loop Engineering 的"阿喀琉斯之踵"

Agent 可以 7×24 跑，但人不能。当 loop 的产出速度远超人的审查速度时，要么接受理解债累积，要么把审查也交给 AI。后者是必然方向，但 AI 审 AI 的可信度目前还是问号。
