# Example: Bug Fix with Two Iterations

Demonstrates the TAV loop where the Verifier catches an incomplete fix and sends the work back to the Actor. This is the core value of independent verification.

## User Request

"Fix the bug where updating a user's nested profile does not save changes to the database"

## Phase 1: Thinker - Analysis

```markdown
**[Thinker - Analysis]**
Phase 1 -> Analyzing

### Task Classification
- Tier: L1
- Risk level: high (possible production data loss)
- Escalation: use `spec-driven-develop` first? no

### Evidence Gathered
- `src/api/user.ts:89-112` - updateProfile mutates `user.profile.displayName` and calls `user.save()` without `await`; the response is sent before the write completes.
- `src/models/User.ts:45-67` - `profile` is declared as `Schema.Types.Mixed`; `save()` returns a Promise.
- Search `user.save()` - 8 call sites; 6 use `await`, 2 do not: `src/api/user.ts:100` and `src/api/admin.ts:234`.
- `tests/api/user.test.ts:120-145` - existing test only asserts the HTTP response, never the database state.

### Analysis Summary
- Missing `await` on `user.save()` causes a race: the response returns before the write. The same defect exists in the admin API. Existing tests cannot catch either an incomplete write or a missed Mongoose change notification because they never read the database back.

### Hard-Bug Evidence
- Not applicable: repository evidence identifies a direct persistence defect and the API integration seam can reproduce it without diagnostic instrumentation.

### Test Seam
- The API integration tests with a post-request database re-read are the highest stable public boundary that proves persistence rather than response-only success.

### Todo List
1. `src/api/user.ts:100` - add `await` before `user.save()`.
2. `src/api/admin.ts:234` - add `await` before `user.save()` (same defect).
3. `tests/api/user.test.ts:145` - after the request, reload the user from the database and assert `profile.displayName`.
4. `tests/api/admin.test.ts:89` - add the same database assertion.

### Risks
- Updates may have been silently lost in production; check error logs separately.
- Tests that now verify database state may expose a Mixed-path change-tracking issue.

### Verification Plan
- `npm test` - full suite; the strengthened tests validate actual persistence.
```

## Phase 2: Actor - Execution

```markdown
**[Actor - Execution]**
Phase 2 -> Executing

### Progress
1. Completed `src/api/user.ts:100` - added `await`.
2. Completed `src/api/admin.ts:234` - added `await`.
3. Completed `tests/api/user.test.ts` - added database re-read assertion.
4. Completed `tests/api/admin.test.ts` - added database re-read assertion.

### Completed Steps
- Todos 1-4 completed; both endpoint changes and database assertions are present in the diff.

### Diagnostic Probe Evidence
- Not applicable.

### TDD Evidence
- The new database assertions were not run RED before the implementation edits; this process gap is visible because the Verifier's first independent run remains red and blocks completion.

### Blocked Items
- None.

### Notes
- No planned deviation reported by the Actor; Verifier still determines whether the persistence proof is green.
```

Representative edit:

```typescript
// tests/api/user.test.ts - strengthened assertion
expect(response.status).toBe(200)
const updatedUser = await User.findById(testUserId)
expect(updatedUser.profile.displayName).toBe('New Name')
```

## Phase 3: Verifier - Review (Iteration 1)

```markdown
**[Verifier - Review]**
Phase 3 -> Reviewing

### Diff Reviewed
- `git diff` shows 4 files: two one-line `await` additions, two test assertions added. Matches the plan.

### Verification Items

| Check | Status | Evidence |
|-------|--------|----------|
| Requirement met | fail | tests prove updates still not persisted |
| Syntax/type safety | pass | tsc clean |
| Tests/lint | fail | 2 tests failing, output below |
| Compatibility | pass | no API shape change |
| Edge cases | warn | no try/catch around save path |
| Security | pass | persistence surface reviewed: test IDs are controlled, queries remain parameterized through Mongoose, and no authorization boundary changed |
| Side effects | pass | no other call sites affected |

### Standards Review
- Status: pass
- Repository-rule evidence: changes stay within the two endpoint and two integration-test files named by the plan; no unrelated refactor is present.

### Spec Review
- Status: fail
- Acceptance evidence: the database re-read still returns `Old Name`, so the requested persistence behavior is not implemented even though `await` was added.

### Hard-Bug Closure
- Not applicable.

### Commands Run
- `npm test` - FAILED: `Expected: "New Name" / Received: "Old Name"` in both new assertions.

### Failed or Skipped Commands
- `npm test` - failed on the two new persistence assertions; no command was skipped.

### Issue Details
- `src/api/user.ts:95-100` - re-read of the endpoint shows a deep mutation under the `profile` `Schema.Types.Mixed` path. Mongoose does not automatically track this special-case mutation, so `save()` has no changed path to persist. The missing `await` was real but incomplete.

### Suggested Fix
- Before `save()`, call `user.markModified('profile')` in both endpoints. Keep the document save path: ordinary declared schema paths can use assignment plus `save()`; this fix is specifically for the `Mixed` path.

### Consolidation Candidates
- Deep mutations beneath a `Schema.Types.Mixed` path require `markModified('profile')` before `save()`. This does not apply to ordinary declared schema paths. Evidence: iteration-1 database re-read failure after the missing `await` was fixed. (Capture signal: non-obvious root cause.)

### Review Result
- Return to Actor with the fix above.

### Change Summary
- Files modified: 4 (from `git diff --stat`)
- Lines changed: +8 -2 (from `git diff --stat`)
- Scope: incomplete persistence fix plus database-state regression assertions
```

## Phase 2: Actor - Execution (Iteration 2)

```markdown
**[Actor - Execution]**
Phase 2 (iteration 2) -> Executing

### Progress
1. Completed `src/api/user.ts:95-100` - called `markModified('profile')` after the nested mutation and before `save()`.
2. Completed `src/api/admin.ts:230-234` - applied the same `profile` change notification.

### Completed Steps
- Returned from the Verifier with the exact Mixed-path evidence and completed the two corrective endpoint edits.

### Diagnostic Probe Evidence
- Not applicable.

### TDD Evidence
| Slice | RED Command / Result | GREEN Command / Result |
|:------|:---------------------|:-----------------------|
| Nested profile persistence | `npm test` - database re-read receives `Old Name` after the incomplete fix | `npm test` - database re-read receives `New Name` after `markModified('profile')` |

### Blocked Items
- None.

### Notes
- The Verifier evidence changed the implementation detail but not the approved persistence behavior or test seam.
```

Representative edit:

```typescript
// Before: profile is Schema.Types.Mixed, so this deep mutation is not tracked.
const user = await User.findById(req.userId)
user.profile.displayName = name
user.profile.bio = bio
await user.save()

// After:
const user = await User.findById(req.userId)
user.profile.displayName = name
user.profile.bio = bio
user.markModified('profile')
await user.save()
```

## Phase 3: Verifier - Review (Iteration 2)

```markdown
**[Verifier - Review]**
Phase 3 (iteration 2) -> Reviewing

### Diff Reviewed
- `git diff` shows both endpoints keep document `save()` and now mark the Mixed `profile` path as modified; test assertions remain unchanged.

### Verification Items

| Check | Status | Evidence |
|-------|--------|----------|
| Requirement met | pass | database assertions pass |
| Syntax/type safety | pass | tsc clean |
| Tests/lint | pass | 5/5 tests pass |
| Compatibility | pass | response shape unchanged |
| Edge cases | pass | `markModified` is limited to the Mixed `profile` path; ordinary schema-path assignment remains unchanged |
| Security | pass | database persistence review repeated; no injection, authorization, or sensitive-error regression found |
| Side effects | pass | other `user.save()` call sites are untouched; no generic replacement of document saves |

### Standards Review
- Status: pass
- Repository-rule evidence: the fix is limited to the two known `Mixed`-path endpoints and keeps the established document-save pattern.

### Spec Review
- Status: pass
- Acceptance evidence: both database re-read assertions now observe `New Name`; response shape and unrelated call sites remain unchanged.

### Hard-Bug Closure
- Not applicable.

### Commands Run
- `npm test` - PASS: `Tests: 5 passed, 5 total`.

### Failed or Skipped Commands
- None.

### Issue Details
- None.

### Suggested Fix
- None.

### Consolidation Candidates
- Carried from iteration 1: deep mutations beneath Mongoose `Mixed` paths require an explicit `markModified`, now confirmed by the passing fix.

### Review Result
- Pass and enter Phase 4.

### Change Summary
- Files modified: 4 (from `git diff --stat`)
- Lines changed: +12 -16 (from `git diff --stat`)
- Scope: profile/admin update persistence fix plus strengthened tests
```

## Phase 4: Completion

Knowledge consolidation fires before the final report: the carried candidate hits capture signal 1 (a non-obvious root cause that will recur). This example assumes `docs/memory/` was already declared in the project's Governance Status. Without that declaration or an explicit user choice, report the candidate instead of creating this file.

```markdown
<!-- docs/memory/mongoose-mixed-change-tracking.md -->
---
name: mongoose-mixed-change-tracking
description: Mark a Mongoose Mixed path after mutating nested properties
type: gotcha
tags: [mongoose, persistence, mixed-schema]
applies_to: [src/api/user.ts, src/api/admin.ts]
---

- After mutating nested properties beneath a `Schema.Types.Mixed` path, call `markModified('<path>')` before `save()` — Why: Mongoose does not automatically track deep Mixed-path mutations; found via a failing database re-read assertion. Apply: only to the affected Mixed path, not ordinary declared schema paths.
```

```markdown
<!-- docs/memory/MEMORY.md -->
- [mongoose-mixed-change-tracking](mongoose-mixed-change-tracking.md): Mongoose Mixed-path persistence rule.
```

```markdown
## Summary
- 用户嵌套资料未持久化的根因是 `profile` 为 Mongoose `Mixed` 路径，其深层修改未被自动追踪；缺失 `await` 同时存在但不足以修复问题。已在两个端点的 `save()` 前调用 `markModified('profile')` 并强化测试以校验数据库真实状态。

## Files Changed
- `src/api/user.ts` (Modified): 更新 `Mixed` 类型的 `profile` 后标记该路径为已修改。
- `src/api/admin.ts` (Modified): 管理端同一 `profile` 变更追踪缺陷同步修复。
- `tests/api/user.test.ts` (Modified): 增加数据库回读断言。
- `tests/api/admin.test.ts` (Modified): 增加数据库回读断言。

## Verification
- ✅ `npm test` passed (5 passing)

## Failed or Skipped Commands
- None.

## Residual Risks
- 生产环境历史丢失的更新无法恢复，建议排查错误日志。

## Next Steps
- 为其余 6 处 `user.save()` 调用补充数据库状态断言。

## Knowledge Consolidation
- `docs/memory/MEMORY.md` (Modified only when the surface is declared): linked the new topic entry.
- `docs/memory/mongoose-mixed-change-tracking.md` (Added only when the surface is declared): Mongoose `Mixed` 路径的深层修改需在保存前标记为已修改。
```

## Key Takeaways

1. **The first fix was plausible and wrong.** Adding `await` matched the symptom; only a test that reads the database back exposed the real defect.
2. **Verifier independence is the safety net.** It re-read the endpoint instead of trusting the Actor's summary, identified the `Mixed`-path change-tracking issue, and returned an exact fix.
3. **The loop is cheap.** One extra Actor-Verifier iteration prevented shipping a fake fix to production.
4. **The lesson outlives the task when governance permits.** Capture the non-obvious root cause in the resolved memory surface; use `docs/memory/` only when it is already declared or explicitly selected.

---

**End of Example**
