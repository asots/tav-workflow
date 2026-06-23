# Example: Bug Fix with TAV Workflow

This example demonstrates using TAV workflow to fix a bug where user profile updates fail silently.

## User Request

"Fix the bug where updating user profile doesn't save changes to the database"

## Phase 1: Thinker — Analysis

### Thinker Output

```markdown
**[Thinker - Analysis]**
Phase 1 → Analyzing

### Evidence Gathered
- Read file: `src/api/user.ts:89-112` — Found updateProfile endpoint
  ```typescript
  router.put('/profile', async (req, res) => {
    const { name, bio, avatar } = req.body
    const user = await User.findById(req.userId)
    user.name = name
    user.bio = bio
    user.avatar = avatar
    // BUG: Missing await on save()
    user.save()
    res.json({ success: true, user })
  })
  ```
- Read file: `src/models/User.ts:45-67` — User model uses Mongoose, save() returns Promise
- Search references: `user.save()` called in 8 places, checked all:
  - 6 places correctly use `await user.save()`
  - 2 places missing `await`: `src/api/user.ts:100` and `src/api/admin.ts:234`
- Read file: `tests/api/user.test.ts:120-145` — Test exists but doesn't verify database state

### Analysis Conclusion
The bug is a missing `await` on `user.save()` at line 100. The response is sent before the database write completes, causing a race condition. The test passes because it only checks the HTTP response, not the actual database state. There's a second instance of the same bug in the admin API.

### Todo-list
1. `src/api/user.ts:100` — Add `await` before `user.save()`
2. `src/api/admin.ts:234` — Add `await` before `user.save()` (same bug)
3. `tests/api/user.test.ts:145` — Add database verification after update
4. `tests/api/admin.test.ts:89` — Add database verification (if test exists)

### Risk Notes
- Both endpoints have the same bug (copy-paste error likely)
- Existing tests don't catch this because they don't verify DB state
- May have caused data loss in production (updates lost)
- Should check error logs for unhandled promise rejections
```

---

## Phase 2: Actor — Execution

### Actor Output

```markdown
**[Actor - Execution]**
Phase 2 → Executing

### Progress
1. ✓ `src/api/user.ts:100` — Added await
2. ✓ `src/api/admin.ts:234` — Added await
3. ✓ `tests/api/user.test.ts:145` — Added DB verification
4. ✓ `tests/api/admin.test.ts:89` — Added DB verification

### Details

**Edit 1: src/api/user.ts**
```typescript
// Before:
user.save()
res.json({ success: true, user })

// After:
await user.save()
res.json({ success: true, user })
```

**Edit 2: src/api/admin.ts**
```typescript
// Before:
user.save()
res.json({ success: true, user })

// After:
await user.save()
res.json({ success: true, user })
```

**Edit 3: tests/api/user.test.ts**
```typescript
it('should update user profile', async () => {
  const response = await request(app)
    .put('/api/user/profile')
    .send({ name: 'New Name', bio: 'New bio' })
  
  expect(response.status).toBe(200)
  expect(response.body.success).toBe(true)
  
  // NEW: Verify database state
  const updatedUser = await User.findById(testUserId)
  expect(updatedUser.name).toBe('New Name')
  expect(updatedUser.bio).toBe('New bio')
})
```

**Edit 4: tests/api/admin.test.ts**
```typescript
it('should update user as admin', async () => {
  const response = await request(app)
    .put('/api/admin/user/123')
    .send({ name: 'Admin Updated' })
  
  expect(response.status).toBe(200)
  
  // NEW: Verify database state
  const updatedUser = await User.findById('123')
  expect(updatedUser.name).toBe('Admin Updated')
})
```

→ Enter Phase 3: Review
```

---

## Phase 3: Verifier — Review

### Verifier Output

```markdown
**[Verifier - Review]**
Phase 3 → Reviewing

### Verification Items

| Check | Status | Notes |
|-------|--------|-------|
| Requirement met | ✓ | Bug fixed in both locations |
| Syntax correct | ✓ | No syntax errors |
| Type safe | ✓ | TypeScript happy |
| Error handling | ⚠ | No try-catch around save() |
| Tests verify DB | ✓ | Tests now check database state |
| All instances fixed | ✓ | Both user.ts and admin.ts fixed |
| Tests pass | ✗ | Tests fail — see below |

### Test Results

```bash
$ npm test

FAIL tests/api/user.test.ts
  ✗ should update user profile (45ms)
    Expected: "New Name"
    Received: "Old Name"

FAIL tests/api/admin.test.ts
  ✗ should update user as admin (32ms)
    Expected: "Admin Updated"
    Received: "Original Name"
```

### Issue Details

**Critical Issue Found:**
Tests are now failing because they reveal the bug was deeper than just missing `await`. After adding `await`, the database still doesn't update.

**Root Cause Analysis:**
- Read `src/api/user.ts:89-112` again
- The issue: `user` object is modified but Mongoose doesn't detect changes
- Mongoose requires either:
  1. `user.markModified('field')` before save, OR
  2. Use `User.findByIdAndUpdate()` instead

**Current code:**
```typescript
const user = await User.findById(req.userId)
user.name = name  // Direct assignment doesn't trigger Mongoose change detection
await user.save() // Saves nothing because no changes detected
```

### Suggested Fix

Return to Actor with new todo:
1. `src/api/user.ts:95-100` — Use `User.findByIdAndUpdate()` instead
2. `src/api/admin.ts:230-234` — Same fix

→ Return to Phase 2: Fix Mongoose change detection
```

---

## Phase 2 (Iteration 2): Actor — Fix Root Cause

### Actor Output

```markdown
**[Actor - Execution]**
Phase 2 (Iteration 2) → Executing

### Progress
1. ✓ `src/api/user.ts:95-100` — Replaced with findByIdAndUpdate
2. ✓ `src/api/admin.ts:230-234` — Replaced with findByIdAndUpdate

### Details

**Edit 1: src/api/user.ts**
```typescript
// Before:
const user = await User.findById(req.userId)
user.name = name
user.bio = bio
user.avatar = avatar
await user.save()
res.json({ success: true, user })

// After:
const user = await User.findByIdAndUpdate(
  req.userId,
  { name, bio, avatar },
  { new: true, runValidators: true }
)
res.json({ success: true, user })
```

**Edit 2: src/api/admin.ts**
```typescript
// Before:
const user = await User.findById(userId)
user.name = name
await user.save()
res.json({ success: true, user })

// After:
const user = await User.findByIdAndUpdate(
  userId,
  { name },
  { new: true, runValidators: true }
)
res.json({ success: true, user })
```

→ Enter Phase 3: Review (Iteration 2)
```

---

## Phase 3 (Iteration 2): Verifier — Re-verify

### Verifier Output

```markdown
**[Verifier - Review]**
Phase 3 (Iteration 2) → Reviewing

### Verification Items

| Check | Status | Notes |
|-------|--------|-------|
| Requirement met | ✓ | Bug fixed correctly |
| Syntax correct | ✓ | No errors |
| Type safe | ✓ | TypeScript correct |
| Mongoose usage | ✓ | findByIdAndUpdate used correctly |
| Validators run | ✓ | runValidators: true included |
| Tests pass | ✓ | All tests pass |
| Error handling | ✓ | Mongoose errors bubble up |

### Test Results

```bash
$ npm test

PASS tests/api/user.test.ts
  ✓ should update user profile (28ms)
  ✓ should validate required fields (15ms)
  ✓ should return 404 for invalid user (12ms)

PASS tests/api/admin.test.ts
  ✓ should update user as admin (22ms)
  ✓ should require admin role (18ms)

Test Suites: 2 passed, 2 total
Tests:       5 passed, 5 total
```

### Review Result

**Status: PASS**

All checks passed. The bug is fixed correctly:
- Database updates now persist
- Tests verify database state
- Mongoose validators run on update
- Error handling works correctly

### Change Summary
- Files modified: 4 (2 source, 2 test)
- Lines changed: +12 -16 (net: -4 lines, simpler code)
- Iterations: 2 (initial fix incomplete, second fix correct)
- Root cause: Mongoose change detection issue

✓ Task complete
```

---

## Final Summary

```markdown
**[TAV Workflow - Complete]**

### Summary
✓ Bug fixed: User profile updates now save correctly

### Root Cause
Missing `await` on `user.save()` was a symptom. Real issue was Mongoose change detection not triggered by direct property assignment.

### Solution
Replaced `findById` + `save()` pattern with `findByIdAndUpdate()` which:
- Directly updates database
- Runs validators
- Returns updated document
- Simpler code (fewer lines)

### Changes
1. src/api/user.ts — Use findByIdAndUpdate for profile updates
2. src/api/admin.ts — Use findByIdAndUpdate for admin updates
3. tests/api/user.test.ts — Added database verification
4. tests/api/admin.test.ts — Added database verification

### Metrics
- Files modified: 4
- Lines changed: +12 -16
- Iterations: 2
- Token usage: 12,456
- Duration: 25 minutes

### Key Learning
Initial analysis was incomplete. Verifier caught this by running tests that verify database state, not just HTTP responses. This demonstrates the value of independent verification.

✓ Task complete
```

---

## Key Takeaways

### Why Two Iterations Were Needed

1. **Thinker's initial analysis was surface-level:**
   - Identified missing `await` (correct symptom)
   - Didn't test the hypothesis (would have revealed deeper issue)
   - Lesson: Run tests during analysis phase when possible

2. **Verifier caught the real issue:**
   - Ran tests that verify database state
   - Tests failed, revealing incomplete fix
   - Returned to Actor with root cause analysis

3. **Second iteration fixed root cause:**
   - Actor applied correct solution
   - Verifier confirmed tests pass
   - Bug fully resolved

### What This Demonstrates

**Value of TAV Workflow:**
- **Thinker:** Found the bug location and initial hypothesis
- **Actor:** Applied fix without over-engineering
- **Verifier:** Caught incomplete fix through independent testing
- **Iteration:** System self-corrected without user intervention

**Importance of Good Tests:**
- Original test only checked HTTP response (false positive)
- Updated test verifies database state (catches real bug)
- Verifier's test-driven verification caught the incomplete fix

### Alternative Approach (Without TAV)

Without structured workflow:
1. Developer sees bug report
2. Adds `await` (seems obvious)
3. Commits without testing
4. Bug persists in production
5. More user complaints
6. Deeper investigation needed

With TAV:
1. Thinker analyzes systematically
2. Actor applies fix
3. Verifier tests independently
4. Catches incomplete fix
5. Second iteration fixes root cause
6. Verified working before commit

---

**End of Example**
