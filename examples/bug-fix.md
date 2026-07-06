# Example: Bug Fix with Two Iterations

Demonstrates the TAV loop where the Verifier catches an incomplete fix and sends the work back to the Actor. This is the core value of independent verification.

## User Request

"Fix the bug where updating user profile doesn't save changes to the database"

## Phase 1: Thinker - Analysis

```markdown
**[Thinker - Analysis]**
Phase 1 -> Analyzing

### Task Classification
- Tier: L1
- Risk level: high (possible production data loss)
- Escalation: use `spec-driven-develop` first? no

### Evidence Gathered
- `src/api/user.ts:89-112` - updateProfile endpoint calls `user.save()` without `await`; response is sent before the write completes.
- `src/models/User.ts:45-67` - User model uses Mongoose; `save()` returns a Promise.
- Search `user.save()` - 8 call sites; 6 use `await`, 2 do not: `src/api/user.ts:100` and `src/api/admin.ts:234`.
- `tests/api/user.test.ts:120-145` - existing test only asserts the HTTP response, never the database state.

### Analysis Summary
- Missing `await` on `user.save()` causes a race: the response returns before the write. The same defect exists in the admin API. Existing tests cannot catch it because they never read the database back.

### Todo List
1. `src/api/user.ts:100` - add `await` before `user.save()`.
2. `src/api/admin.ts:234` - add `await` before `user.save()` (same defect).
3. `tests/api/user.test.ts:145` - after the request, reload the user from the database and assert the new values.
4. `tests/api/admin.test.ts:89` - same database assertion.

### Risks
- Updates may have been silently lost in production; check error logs separately.
- Tests that now verify database state may expose deeper persistence issues.

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

### Blocked Items
- None.

### Next Phase
- Enter Verifier.
```

Representative edit:

```typescript
// tests/api/user.test.ts - strengthened assertion
expect(response.status).toBe(200)
const updatedUser = await User.findById(testUserId)
expect(updatedUser.name).toBe('New Name')
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
| Security | pass | no sensitive surface touched |
| Side effects | pass | no other call sites affected |

### Commands Run
- `npm test` - FAILED: `Expected: "New Name" / Received: "Old Name"` in both new assertions.

### Issue Details
- `src/api/user.ts:95-100` - re-read of the endpoint shows direct property assignment on a Mongoose document; change detection is not triggered, so `save()` persists nothing. The missing `await` was a symptom, not the root cause.

### Suggested Fix
- Replace the `findById` + assign + `save()` pattern with `User.findByIdAndUpdate(..., { new: true, runValidators: true })` in both endpoints.

### Review Result
- Return to Actor with the fix above.
```

## Phase 2: Actor - Execution (Iteration 2)

```markdown
**[Actor - Execution]**
Phase 2 (iteration 2) -> Executing

### Progress
1. Completed `src/api/user.ts:95-100` - replaced with `findByIdAndUpdate`.
2. Completed `src/api/admin.ts:230-234` - replaced with `findByIdAndUpdate`.

### Blocked Items
- None.

### Next Phase
- Enter Verifier.
```

Representative edit:

```typescript
// Before:
const user = await User.findById(req.userId)
user.name = name
user.bio = bio
user.avatar = avatar
await user.save()

// After:
const user = await User.findByIdAndUpdate(
  req.userId,
  { name, bio, avatar },
  { new: true, runValidators: true }
)
```

## Phase 3: Verifier - Review (Iteration 2)

```markdown
**[Verifier - Review]**
Phase 3 (iteration 2) -> Reviewing

### Diff Reviewed
- `git diff` shows both endpoints now use `findByIdAndUpdate` with `runValidators`; test assertions unchanged.

### Verification Items

| Check | Status | Evidence |
|-------|--------|----------|
| Requirement met | pass | database assertions pass |
| Syntax/type safety | pass | tsc clean |
| Tests/lint | pass | 5/5 tests pass |
| Compatibility | pass | response shape unchanged |
| Edge cases | pass | validators run on update |
| Security | pass | no new surface |
| Side effects | pass | other `user.save()` call sites untouched |

### Commands Run
- `npm test` - PASS: `Tests: 5 passed, 5 total`.

### Issue Details
- None.

### Review Result
- Pass and enter Phase 4.

### Change Summary
- Files modified: 4 (from `git diff --stat`)
- Lines changed: +12 -16 (from `git diff --stat`)
- Scope: profile/admin update persistence fix plus strengthened tests
```

## Phase 4: Completion

```markdown
## 变更摘要
- 用户资料更新未持久化的根因是 Mongoose 变更检测未触发（直接属性赋值 + `save()`），而非最初诊断的缺失 `await`。已在两个端点改用 `findByIdAndUpdate` 并强化测试以校验数据库真实状态。

## 涉及文件
- `src/api/user.ts` (Modified): updateProfile 改用 findByIdAndUpdate。
- `src/api/admin.ts` (Modified): 管理端同一缺陷同步修复。
- `tests/api/user.test.ts` (Modified): 增加数据库回读断言。
- `tests/api/admin.test.ts` (Modified): 增加数据库回读断言。

## 验证结果
- ✅ `npm test` passed (5 passing)

## 失败或未执行的命令
- None.

## 剩余风险
- 生产环境历史丢失的更新无法恢复，建议排查错误日志。

## 后续建议
- 为其余 6 处 `user.save()` 调用补充数据库状态断言。
```

## Key Takeaways

1. **The first fix was plausible and wrong.** Adding `await` matched the symptom; only a test that reads the database back exposed the real defect.
2. **Verifier independence is the safety net.** It re-read the endpoint instead of trusting the Actor's summary, found the change-detection issue, and returned an exact fix.
3. **The loop is cheap.** One extra Actor-Verifier iteration prevented shipping a fake fix to production.

---

**End of Example**
