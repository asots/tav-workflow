# TAV Workflow - 使用说明

[English](README.md) | 简体中文

## 概述

TAV（Think-Act-Verify，思考-执行-验证）是一个面向范围明确的软件变更的结构化工作流。它将分析、执行、验证三种职责分离，确保每一次非平凡的修改都基于证据、保持最小化、并在宣告完成前经过独立检查。

**版本**：3.6.0
**状态**：Stable

权威规范位于 [SKILL.md](SKILL.md)。本 README 面向读者提供概览；schema、命令表、输出契约只在 skill 文件中定义一次，此处仅作引用。

## 快速开始

当一个请求会改变代码、配置、依赖、测试、工作流或部署清单时，使用 TAV。

```text
用户请求："修复结算校验的 bug"

TAV 工作流：
1. Phase 0 检查 `.tav/state.json` 是否有可恢复的工作（仅 L1，L0 跳过）。
2. Thinker 收集证据并写出原子化计划。
3. Actor 只执行计划内的修改。
4. Verifier 审查真实 diff，运行与技术栈匹配的检查，排查副作用。
5. Completion 报告修改文件、验证结果、跳过的检查与剩余风险。
```

## 适用场景

### 使用 TAV

- Bug 修复。
- 范围明确的功能实现。
- 目标行为明确的局部重构。
- 配置更新。
- 依赖或工作流调整。

### 使用其他方案

- 纯只读问答：直接回答。
- 重写、迁移、架构改造、多阶段转型：先运行 `spec-driven-develop`，再对每个拆分后的任务应用 TAV。

## 任务分级

| 级别 | 范围 | 工作流 |
|------|------|--------|
| L0 | 微小改动或显而易见的单文件补丁 | 单遍轻量 TAV：收集证据、实施修改、运行基线检查。不创建状态文件。 |
| L1 | 跨多文件的标准 bug 修复或功能实现 | 完整的 Thinker -> Actor -> Verifier 工作流 |
| L2 | 架构、迁移、schema、认证改造、分布式流程 | 先 `spec-driven-develop`，再对每个拆分任务应用 TAV |

## 核心特性

- **角色分离**：只读的 Thinker、最小变更的 Actor、从 `git diff` 出发（而非 Actor 汇报）的独立 Verifier；安全敏感或返工两次的变更会升级为由独立 reviewer agent 进行验证。
- **状态持久化**：`.tav/state.json` 支持恢复被中断的 L1 工作；超过 7 天的状态视为过期。schema 见 [SKILL.md](SKILL.md) Phase 0，完整模板见 [references/templates/state.json](references/templates/state.json)。
- **原生任务跟踪**：进度映射到平台的真实任务工具（Claude Code 中为 `TaskCreate` / `TaskUpdate`）。
- **栈感知质量门禁**：验证命令基于仓库证据选择（lockfile、`pyproject.toml`、`Cargo.toml`、`go.mod`、CI 配置）。完整表格见 [SKILL.md](SKILL.md) Phase 3。
- **错误恢复**：计划不匹配时返回 Thinker，门禁失败时返回 Actor，同一阻塞点失败两次触发 `[PUA-REPORT]` 升级，关键安全问题阻断完成。
- **知识沉淀**：门禁通过后，将持久化的经验教训（非显而易见的根因、未记录的命令、依赖坑）沉淀到项目的 `docs/memory/` 目录——每轮循环最多 1-3 条，由下一次 Thinker 索引召回并重新校验。见 [SKILL.md](SKILL.md) Phase 4。
- **Spec-driven 互操作**：在 `spec-driven-develop` 项目内，一个 TAV 循环执行一张任务卡并回写进度与遥测。见 [SKILL.md](SKILL.md) "Operating Inside a Spec-Driven Project"。

## 架构

```text
用户请求
    |
Phase 0: 连续性检查（仅 L1）
    |-- 相关且未过期时加载 `.tav/state.json`
    |
Phase 1: Thinker
    |-- 证据、诊断、待办清单、风险、验证计划
    |
Phase 2: Actor
    |-- 只做计划内的最小编辑
    |
Phase 3: Verifier
    |-- git diff 审查、测试/lint/类型检查、安全检查
    |
Phase 4: Completion
    |-- 知识沉淀、最终报告、状态清理/归档
```

## 状态文件

位置：`.tav/state.json`（仅当工作可能跨会话或多次迭代时创建）。

建议的 `.gitignore` 条目：

```gitignore
.tav/
```

注意：知识沉淀目录 `docs/memory/` 需要随仓库提交，**不要**将其加入 `.gitignore`。

## 示例

- [examples/bug-fix.md](examples/bug-fix.md) - Verifier 捕获不完整修复的两轮迭代，含完整知识沉淀链路演示。
- [examples/rate-limiting.md](examples/rate-limiting.md) - 完整 L1 演练，含状态文件演化。
- [examples/refactoring.md](examples/refactoring.md) - 行为保持的提取重构，含计划不匹配恢复演示。
- [examples/l0-quick-patch.md](examples/l0-quick-patch.md) - L0 轻量单遍流程，不建状态文件。
- [examples/pua-escalation.md](examples/pua-escalation.md) - 两次同阻塞失败触发 `[PUA-REPORT]` 与验证独立性升级。

## 文档

- [SKILL.md](SKILL.md) - 完整技能规范（单一真理源）。
- [CHANGELOG.md](CHANGELOG.md) - 版本历史。
- [实现指南](references/implementation-guide.md) - 操作细节。
- [状态模板](references/templates/state.json) - 持久化状态 schema。
- [Thinker 输出](references/templates/thinker-output.md) / [Actor 输出](references/templates/actor-output.md) / [Verifier 输出](references/templates/verifier-output.md) - 阶段输出格式。
- [CONTRIBUTING.md](CONTRIBUTING.md) - 如何编辑本技能并运行文档自检。

## 许可证

MIT

---

**TAV Workflow v3.6.0**
*Think-Act-Verify：基于证据的变更、最小化执行、经验证的完成。*
