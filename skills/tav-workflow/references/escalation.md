# Failure Counting and Escalation

`SKILL.md` keeps the two-strike summary in "Error Recovery and Escalation"; this file owns the full counting rules and the report format.

### Failure counting semantics

The "same blocker fails twice" rule needs a stable key so the count is meaningful:

- **Blocker key** = `todo_id` (or the verification command string when the failure is a gate command) + a normalized error signature. Normalize by keeping the stable part (error type/code, failing rule or test name) and stripping volatile parts (line numbers, file offsets, timestamps, memory addresses) — `TS2532`, not `TS2532-dashboard.ts:8`. Record the normalized key from the first failure; never widen a key after the fact to make two failures match. Store it under `failure_counts.by_blocker` for plan/structural failures and `failure_counts.by_command` for gate-command failures.
- **Consecutive**: only consecutive failures of the *same* key count. A success or a Thinker re-plan resets the counter for that key.
- **Count only unexpected comparable failures**: expected TDD RED results, pre-change baseline failures, hypothesis probes, intentionally incomplete intermediate checks, and confirmed environment/infrastructure failures do not increment the counter. Record them as evidence under their own lifecycle instead.
- **Two-strike trigger**: the second consecutive failure of the same key emits `[ESCALATION-REPORT]`, requires an independent Verifier when available, and returns to Thinker for a re-plan before more implementation. A third is not required — escalate on two. This verification escalation does not itself require user approval; request an explicit user decision only if the safe next step changes the approved spec, acceptance criteria, architecture, rollback boundary, irreversible operation, or external authority.
- **Re-plan resets**: when the Thinker revises the todo list after a return, all `failure_counts` entries for the superseded todos are cleared, because the blocker key is no longer valid.

Never reset a counter to avoid escalation. If the same root cause keeps surfacing under different keys, treat that as a Thinker signal that the diagnosis is wrong.

### Escalation report format

```text
[ESCALATION-REPORT]
- 触发节点：[Agent Name / Current Phase Name]
- 失败次数：[Exact consecutive failure count]
- 核心瓶颈：[Precise technical blocker]
- 异常上下文：[Terminal traces, exception stack, or error block]
- 纠正性复盘：[Logic correction and next safe action]
```
