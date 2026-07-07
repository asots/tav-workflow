# Example: PUA Escalation After Two Consecutive Failures

Demonstrates the two-strike `[PUA-REPORT]` rule. The Actor attempts the same fix twice; the Verifier fails on the same blocker key both times. The second consecutive failure emits a `[PUA-REPORT]` and escalates verification independence — the agent that wrote the fix twice is the least likely to see what is still wrong with it.

## User Request

"`getUser` can return null and crashes the dashboard. Make it safe."

## Phase 1: Thinker

- `src/api/user.ts:20` - `getUser(id): User` calls `fetchUser` (line 25) which returns `User | null`; the `User` return type hides the null.
- `src/dashboard.ts:8` - `getUser(1).name` throws when `getUser` returns null.
- Plan: narrow `getUser`'s return type to `User | null` and handle null at the call site.
- Verification plan (candidate): `pnpm typecheck`, `pnpm test`.

## Phase 2: Actor (Iteration 1)

Changed `getUser` return type to `User | null`:

```typescript
export function getUser(id: number): User | null {
  return fetchUser(id);
}
```

## Phase 3: Verifier (Iteration 1)

- `git diff`: return type widened to `User | null`. Matches the plan.
- `pnpm typecheck`: **FAIL** - `src/dashboard.ts:8` - `Object is possibly 'null'.` (TS2532).
- Blocker key recorded in `failure_counts.by_command`: `pnpm typecheck:TS2532` = 1. The signature keeps the stable error code and strips the volatile location (`dashboard.ts:8`), per SKILL.md § "Failure counting semantics".
- Result: return to Actor with the exact error.

## Phase 2: Actor (Iteration 2)

Added a non-null assertion at the call site:

```typescript
// src/dashboard.ts:8
const name = getUser(1)!.name;
```

## Phase 3: Verifier (Iteration 2)

- `git diff`: non-null assertion added at `src/dashboard.ts:8`.
- `pnpm typecheck`: **FAIL** - same `TS2532` family, now on `src/dashboard.ts:12` where `getUser(1).email` is used. The assertion suppressed one site but the underlying null-handling is still missing.
- Blocker key `pnpm typecheck:TS2532` is now **2 consecutive** failures. Because the key was normalized (location stripped) from the first failure, the new location (line 12 instead of line 8) still hits the same key — no after-the-fact widening needed.
- Second consecutive failure of the same key -> emit `[PUA-REPORT]` and escalate.

## [PUA-REPORT]

```text
[PUA-REPORT]
- 触发节点：Verifier / Phase 3 (iteration 2)
- 失败次数：2 (consecutive, key=pnpm typecheck:TS2532)
- 核心瓶颈：Suppressing null with `!` at individual call sites does not fix the null-safety defect; TS2532 keeps surfacing at new sites.
- 异常上下文：pnpm typecheck -> TS2532 at src/dashboard.ts:8 (iter 1) then src/dashboard.ts:12 (iter 2).
- 惩罚性反思：The Actor treated the symptom (one type error) twice instead of the root cause (no null guard on the getUser result). Escalate to an independent reviewer agent; the same agent is unlikely to see the missing guard it has now twice avoided.
```

## Escalation

The `[PUA-REPORT]` triggers two things:

1. **Verification independence**: the Verifier is promoted to an independent reviewer agent (not the agent that wrote both fixes). Per the risk-level dynamics, two rework iterations on a null-safety surface escalate risk to **high**.
2. **Thinker re-diagnosis**: the plan is incomplete — "handle null at the call site" was under-specified. The Thinker revises the todo list, which **resets** the `failure_counts` entry for the superseded todos (the blocker key is no longer valid).

Revised Thinker plan:

- `src/dashboard.ts` - guard the whole `getUser` result once: `const user = getUser(1); if (!user) return <EmptyState />;` then use `user.name` / `user.email`.
- `tests/dashboard.test.ts` - add a null-return case asserting `EmptyState` renders.

## Phase 2 + 3 (Iteration 3, under independent review)

Actor applies the single guard. The independent Verifier reviews the `git diff`, runs `pnpm typecheck` (PASS) and `pnpm test` (PASS, including the new null case). The blocker key is gone; no new failures.

## Phase 4: Completion

```markdown
## Summary
- Made `getUser` null-safe by widening its return type to `User | null` and guarding the result once in the dashboard, rather than suppressing each access with `!`.

## Files Changed
- `src/api/user.ts` (Modified): return type `User` -> `User | null`.
- `src/dashboard.ts` (Modified): early-return guard on the `getUser` result.
- `tests/dashboard.test.ts` (Modified): null-return case added.

## Verification
- ✅ `pnpm typecheck` passed
- ✅ `pnpm test` passed (8 passing)

## Residual Risks
- Other `getUser` call sites were not audited; flag for a follow-up pass.

## Next Steps
- Audit remaining `getUser` call sites for the same null-handling gap.

## Knowledge Consolidation
- `docs/memory/null-guard-at-source.md` (Added) - Widen nullable return types and guard once at the call site; do not suppress null with `!` per access — it only relocates the TS2532. Capture signal: same blocker failed twice.
```

## Key Takeaways

1. **Two strikes, not three.** The second consecutive failure of the same blocker key emits `[PUA-REPORT]` immediately.
2. **Escalation is structural, not just a report.** Verification independence is promoted and the Thinker re-plans; the counter resets because the old blocker key is no longer valid.
3. **Suppressing symptoms fails twice.** Both Actor attempts patched one type error instead of adding the missing guard — the classic pattern the two-strike rule exists to catch.
