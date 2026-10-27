# 统一变更分类标准

**版本**: 1.2.0  
**适用 Skills**: tav-workflow 3.21.0+, spec-driven-develop 1.30.0+, write-notes-like-deepseek 1.0.0+  
**最后更新**: 2026-10-27

## 目的

为 tav-workflow 和 spec-driven-develop 提供统一的变更分类标准，避免两个 skills 使用不同的升级判定规则。

---

## 三级分类体系

| 级别 | 名称 | 典型场景 | 使用 Skill |
|------|------|---------|-----------|
| **L0** | 微调 | 单文件、~30 行以内、无运行时/契约/安全影响 | 轻量 TAV 单遍：引用证据、编辑、跑基线检查；不建状态文件、不写阶段模板 |
| **L1** | 任务 | 单模块、明确边界、单 TAV 周期可完成 | tav-workflow |
| **L2** | 项目 | 跨模块、架构决策、需要分解编排 | spec-driven-develop |

---

## L2 升级信号（Escalation Signals）

**判定规则**：至少满足**两个**信号才升级到 L2。

| 信号 | 描述 | 示例 |
|------|------|------|
| **S1: 广度** | 跨 3+ 模块或破坏公共契约 | REST→gRPC 迁移涉及 API、Service、Client 三层 |
| **S2: 长度** | 跨多会话或 ~10+ 文件 | 整个认证系统重构，涉及 15 个文件 |
| **S3: 复杂度** | 需要架构决策（选型、分层、协议） | 选择状态管理方案（Redux vs MobX vs Zustand） |
| **S4: 验收** | 验收标准超出单 TAV 周期 | 需要性能基准、兼容性矩阵、多环境测试 |

### 边缘案例处理

| 案例 | 信号计数 | 分类 | 理由 |
|------|---------|------|------|
| 10 个文件，但都是复制粘贴同一模式 | S2 (1) | L1 | 无架构决策，可脚本化 |
| 2 个文件，但需要选择数据库 | S3 (1) | L1 | 架构决策可在 TAV Phase 1 处理 |
| 跨 4 个模块 + 需要新协议设计 | S1 + S3 (2) | L2 | 满足两个信号 |
| 单文件，但需要 A/B 测试 + 性能监控 | S4 (1) | L1 | 验收复杂但范围小 |

---

## 分类决策树

```
开始
  ↓
是否只是调参数/改文案/修拼写，且不触及运行时/安全/数据/公共契约？（调参数不得改变运行时默认或公共配置语义）
  ├─ 是 → L0（轻量 TAV 单遍）
  └─ 否 ↓
      ↓
计算满足的 L2 信号数量（S1-S4）
  ↓
信号数量 ≥ 2？
  ├─ 是 → L2（使用 spec-driven-develop）
  └─ 否 → L1（使用 tav-workflow）
```

---

## 实际案例映射

### L0 案例

| 请求 | 信号 | 分类 |
|------|------|------|
| "Fix typo in error message" | 0 | L0 |
| "Fix a documentation-only default note" | 0 | L0 |
| "Update README with new API endpoint" | 0 | L0 |

### L1 案例

| 请求 | 信号 | 分类 |
|------|------|------|
| "Bump timeout from 3s to 5s" | 0（单文件，但改变运行时默认） | L1 |
| "Fix null pointer in UserService" | 0（单模块、局部） | L1 |
| "Add email validation to signup form" | 0（单模块、<10 文件） | L1 |
| "Refactor AuthController to use strategy pattern" | S3（单模块内的结构决策） | L1 |
| "Add pagination to /users API" | 0-1（5-6 文件，未跨 3 模块） | L1 |

### L2 案例

| 请求 | 信号 | 分类 |
|------|------|------|
| "Migrate from REST to gRPC" | S1 (跨层) + S2 (15+ files) + S3 (协议) | L2 (3 signals) |
| "Rewrite frontend from React to Vue" | S1 (整个前端) + S2 (50+ files) + S4 (兼容性) | L2 (3 signals) |
| "Extract shared logic into microservice" | S1 (新服务边界) + S3 (服务拆分) + S4 (部署策略) | L2 (3 signals) |
| "Add caching layer with Redis" | S1 (跨模块) + S3 (缓存策略) | L2 (2 signals) |
| "Implement multi-tenancy" | S1 (全局影响) + S3 (数据隔离) + S4 (测试矩阵) | L2 (3 signals) |

---

## 中文触发词映射

### L2 中文触发词（需配合信号判定）

| 中文关键词 | 对应信号 | 说明 |
|-----------|---------|------|
| 整体重构 | S1 + S2 | 暗示跨模块 + 多文件 |
| 全项目重构 | S1 + S2 | 明确全局影响 |
| 跨模块迁移 | S1 | 明确跨模块 |
| 架构级改造 | S3 | 明确架构决策 |
| 大规模 XXX | S2 | 暗示多文件 |
| 规范驱动 XXX | 无固定信号 | 只是工作流偏好，按实际范围评估 |

**重要**：单独出现这些词不足以判定 L2，必须验证至少两个信号。

例如：
- "跨模块重构用户模块" → S1 (1 signal) → L1（只有一个信号）
- "跨模块重构 + 需要选择新框架" → S1 + S3 (2 signals) → L2

---

## Skills 如何使用此标准

### TAV Workflow (Phase 0)

```markdown
## Phase 0: L2 信号判定

读取: references/change-classification.md（本 skill 的 references/ 目录内）

判定流程:
1. 检查是否为 L0（调参数、改文案、修拼写）
   - 是 → 直接执行，跳过 TAV
   - 否 → 继续

2. 评估 L2 信号（S1-S4）
   - 满足 ≥ 2 个 → 提示使用 spec-driven-develop
   - 满足 < 2 个 → 继续 TAV Phase 1

3. 边缘案例：
   - 如果用户说"整体重构"但实际只改 3 个文件 → 以实际范围为准（L1）
   - 如果用户说"小调整"但实际跨 4 个模块 → 以实际范围为准（L2）
```

### Spec-Driven Develop (Phase 0)

```markdown
## Phase 0: 适用性验证

读取: references/change-classification.md（本 skill 的 references/ 目录内）

验证流程:
1. 评估 L2 信号
   - 满足 < 2 个 → 拒绝，提示使用 tav-workflow
   - 满足 ≥ 2 个 → 继续 Phase 1

2. 告知用户:
   "检测到 X 个 L2 信号: [列出信号]
   将使用 spec-driven-develop 7 阶段流程"
```

---

## 维护协议

### 修改此标准时

1. 更新版本号（语义化版本）
2. 同时更新依赖此文档的 skills:
   - `tav-workflow/SKILL.md` § "Task Tiering" 与 § "L2 Escalation Signals"
   - `spec-driven-develop/SKILL.md` § "Escalation Signals"
   - `write-notes-like-deepseek/SKILL.md` § "红线"
3. 将本文件同步到每个 skill 的 `references/change-classification.md`，三份内容必须逐字一致

### 版本兼容性

| change-classification.md | tav-workflow | spec-driven-develop | write-notes-like-deepseek |
|-------------------------|--------------|---------------------|---------------------------|
| 1.0.0 | 3.20.0+ | 1.29.0+ | 1.0.0+ |
| 1.1.0 | 3.20.0+ | 1.29.0+ | 1.0.0+ |
| 1.2.0 | 3.21.0+ | 1.30.0+ | 1.0.0+ |

---

## 常见问题

### Q1: 用户说"小改"但实际很大，怎么办？

**A**: 以实际评估的信号为准，而非用户描述。如果评估出 ≥2 个信号，应该提示升级到 L2，即使用户说"小改"。

示例：
```
用户: "小改一下认证流程"
评估: 涉及 API、Service、DB 三层（S1）+ 12 个文件（S2）
决策: L2，提示使用 spec-driven-develop
回复: "虽然你说'小改'，但这个任务涉及 3 层架构和 12 个文件，
      满足 2 个 L2 信号，建议使用 spec-driven-develop 分解后执行。"
```

### Q2: 两个 skills 对同一任务的分类不一致怎么办？

**A**: 这不应该发生。两个 skills 都读取同一份 `change-classification.md`，使用完全相同的判定规则。如果发生不一致，说明其中一个 skill 的 Phase 0 实现有 bug，需要修复。

### Q3: "整体重构"这种词一定是 L2 吗？

**A**: 不一定。需要验证实际信号：
- "整体重构用户模块"但只改 5 个文件 → S2 (1 signal) → L1
- "整体重构认证系统"涉及 API+Service+DB 三层 + 15 个文件 → S1 + S2 (2 signals) → L2

中文触发词只是**提示**，不是**决定性证据**。

### Q4: 如果用户坚持用 TAV 处理 L2 任务怎么办？

**A**: 尊重用户选择，但记录风险：
```
用户明确要求使用 tav-workflow，尽管任务满足 2 个 L2 信号。
继续执行，但可能遇到以下问题：
- TAV 单周期可能无法完成全部变更
- 验收标准可能超出 Phase 3 能力
- 建议在遇到困难时切换到 spec-driven-develop
```

---

**文档所有者**: tav-workflow, spec-driven-develop, write-notes-like-deepseek  
**审核周期**: 每季度或重大变更时  
**反馈渠道**: 在使用中遇到分类模糊的案例时，记录到 `.agents/notes/proposed/classification-edge-cases.md`
