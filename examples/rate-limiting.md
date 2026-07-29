# Example: Add API Rate Limiting (Full L1 Walkthrough)

Demonstrates a complete single-iteration TAV run including `.tav/state.json` evolution. Role names are responsibilities; use whatever planning/execution/review capability the current platform provides.

## User Request

"Add rate limiting to the user login API to prevent brute force attacks"

## Phase 0: Continuity Check

- `.tav/state.json` not found - fresh start.
- Task spans multiple files and touches an auth surface: tier L1, and the state file is worth creating because a security review iteration is likely.

## Phase 1: Thinker - Analysis

```markdown
**[Thinker - Analysis]**
Phase 1 -> Analyzing

### Task Classification
- Tier: L1
- Risk level: high (authentication surface)
- Escalation: use `spec-driven-develop` first? no

### Evidence Gathered
- `src/api/auth.ts:23-45` - Express login route, no rate limiting middleware.
- `src/api/auth.ts:67` - separate OAuth callback route; must NOT be rate limited.
- `package.json:15-30` - Express 4.x present; no rate limiting package installed.
- `src/config/redis.ts:1-20` - Redis client already configured; distributed limiting is feasible.
- `src/middleware/` - middleware directory exists with established patterns.

### Analysis Summary
- User-approved availability policy: fail closed. If Redis is unavailable, login returns 500 rather than silently allowing unbounded authentication attempts. Add `express-rate-limit` with a Redis store so limits hold across instances. Apply only to the login route. Thresholds: 5 attempts per 15 minutes per IP (check latest package versions on the registry before pinning).

### Hard-Bug Evidence
- Not applicable: this is a planned security feature, not a diagnosis/debugging task.

### Test Seam
- `tests/api/auth.test.ts` exercises the public login HTTP route with the configured Redis-backed limiter; it can prove the sixth attempt returns 429 while the OAuth callback remains unaffected.

### Todo List
1. `package.json` - add `express-rate-limit` and `rate-limit-redis` (versions from registry).
2. `src/middleware/rateLimiter.ts` - create `loginLimiter` using the existing Redis client, standard headers on, 429 handler.
3. `src/api/auth.ts:23` - apply `loginLimiter` to the login route only.
4. `tests/api/auth.test.ts` - add test: 6th failed attempt returns 429.

### Risks
- Redis unavailability intentionally fails closed (login returns 500); availability impact is accepted to preserve brute-force protection.
- OAuth callback must remain unlimited.
- Auth surface: Verifier must run the security-sensitive branch.

### Verification Plan
- `npm run lint`, `npm run typecheck` - project scripts confirmed in `package.json`.
- `npm test -- auth.test.ts` - new and existing auth tests.
```

### State After Thinker

`.tav/state.json` (abbreviated; full schema in `references/templates/state.json`):

```json
{
  "version": "3.12.0",
  "task_id": "tav-20260706-083000",
  "user_request": "Add rate limiting to the user login API to prevent brute force attacks",
  "task_tier": "L1",
  "current_phase": "actor",
  "current_risk_level": "high",
  "last_update": "2026-07-06T08:35:00Z",
  "todo_list": [
    { "id": 1, "phase": "actor", "file": "package.json", "line": null, "action": "Add express-rate-limit and rate-limit-redis", "risk": "low", "status": "pending" },
    { "id": 2, "phase": "actor", "file": "src/middleware/rateLimiter.ts", "line": null, "action": "Create loginLimiter with Redis store", "risk": "medium", "status": "pending" },
    { "id": 3, "phase": "actor", "file": "src/api/auth.ts", "line": 23, "action": "Apply loginLimiter to login route only", "risk": "medium", "status": "pending" },
    { "id": 4, "phase": "actor", "file": "tests/api/auth.test.ts", "line": null, "action": "Add 429 rate limit test", "risk": "low", "status": "pending" }
  ],
  "completed_steps": [],
  "verification_commands": [
    { "command": "npm run lint", "reason": "script exists in package.json", "status": "pending" },
    { "command": "npm run typecheck", "reason": "script exists in package.json", "status": "pending" },
    { "command": "npm test -- auth.test.ts", "reason": "auth suite covers the change", "status": "pending" }
  ],
  "failure_counts": { "by_blocker": {}, "by_command": {} }
}
```

## Phase 2: Actor - Execution

```markdown
**[Actor - Execution]**
Phase 2 -> Executing

### Progress
1. Completed `package.json` - added both dependencies.
2. Completed `src/middleware/rateLimiter.ts` - created loginLimiter.
3. Completed `src/api/auth.ts:23` - middleware applied to login route only.
4. Completed `tests/api/auth.test.ts` - added 429 test.

### Completed Steps
- Todos 1-4 completed without deviating from the approved fail-closed policy.

### Diagnostic Probe Evidence
- Not applicable.

### TDD Evidence
| Slice | RED Command / Result | GREEN Command / Result |
|:------|:---------------------|:-----------------------|
| Sixth login attempt | `npm test -- auth.test.ts` - new assertion fails before middleware | `npm test -- auth.test.ts` - 429 assertion passes after middleware |

### Blocked Items
- None.

### Notes
- No deviation from the Thinker plan.
```

Core new file:

```typescript
// src/middleware/rateLimiter.ts
import rateLimit from 'express-rate-limit'
import RedisStore from 'rate-limit-redis'
import { redisClient } from '../config/redis'

export const loginLimiter = rateLimit({
  store: new RedisStore({ client: redisClient, prefix: 'rl:login:' }),
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: 'Too many login attempts, please try again later'
    })
  }
})
```

State after Actor: `current_phase` -> `"verifier"`, all todo items `"status": "done"`, `completed_steps` filled, `last_update` refreshed.

## Phase 3: Verifier - Review

```markdown
**[Verifier - Review]**
Phase 3 -> Reviewing

### Diff Reviewed
- `git diff` shows 3 modified files + 1 new middleware file; no unrelated changes.

### Verification Items

| Check | Status | Evidence |
|-------|--------|----------|
| Requirement met | pass | 6th attempt returns 429 in test |
| Syntax/type safety | pass | `npm run typecheck` clean |
| Tests/lint | pass | lint clean; auth suite 6/6 |
| Compatibility | pass | grep confirms loginLimiter used only at auth.ts:23; OAuth route untouched |
| Edge cases | pass | user-approved fail-closed policy: Redis outage returns 500 rather than bypassing rate limiting |
| Security | pass | security branch run: no secrets, no injection, headers on, auth flow intact |
| Side effects | pass | no other route consumes the middleware |

### Standards Review
- Status: pass
- Repository-rule evidence: middleware follows the existing directory pattern; lint and typecheck are clean.

### Spec Review
- Status: pass
- Acceptance evidence: only login is rate limited, OAuth remains unlimited, and the user-approved Redis fail-closed policy is preserved.

### Hard-Bug Closure
- Not applicable.

### Commands Run
- `npm run lint` - passed.
- `npm run typecheck` - passed.
- `npm test -- auth.test.ts` - passed (6 tests).

### Failed or Skipped Commands
- None.

### Issue Details
- None. Redis outage behavior is an explicit, user-approved fail-closed policy.

### Suggested Fix
- None. A future fail-open policy would change the approved security trade-off and requires a new decision.

### Consolidation Candidates
- None. The Redis policy is recorded in the task definition, and the OAuth exemption is derivable from the route structure (never-capture: code-derivable facts).

### Review Result
- Pass and enter Phase 4.

### Change Summary
- Files modified: 3, files created: 1 (from `git diff --stat`)
- Lines changed: +52 -1 (from `git diff --stat`)
- Scope: login rate limiting with Redis-backed store
```

## Phase 4: Completion

```markdown
## Summary
- 为登录接口添加基于 Redis 的分布式限流（每 IP 15 分钟 5 次），OAuth 回调不受影响。

## Files Changed
- `package.json` (Modified): 新增 express-rate-limit 与 rate-limit-redis。
- `src/middleware/rateLimiter.ts` (Added): loginLimiter 中间件。
- `src/api/auth.ts` (Modified): 登录路由挂载限流中间件。
- `tests/api/auth.test.ts` (Modified): 新增 429 限流测试。

## Verification
- ✅ `npm run lint` passed
- ✅ `npm run typecheck` passed
- ✅ `npm test -- auth.test.ts` passed (6 passing)

## Failed or Skipped Commands
- None.

## Residual Risks
- Redis 不可用时登录路径会按已批准的 fail-closed 策略返回 500；若改为 fail-open，需新的安全决策。

## Next Steps
- 评估按账号维度的二级限流以覆盖分布式攻击源。
```

State cleanup: after explicit cleanup authorization, archive `.tav/state.json` to `.tav/archive/` because it belongs to this completed workflow. Without that authorization, preserve it with `current_phase: complete` and `cleanup_status: awaiting_authorization`.

## Alternative Scenarios

**Redis not available in the project** - Thinker plans an in-memory limiter instead and documents the single-instance limitation in the todo list.

**Verifier finds OAuth affected** - `Compatibility: fail`, return to Actor with one item: remove the middleware from the OAuth route.

**Actor finds class-based controllers instead of Express routes** - structural mismatch with the plan; stop, return to Thinker with the evidence, re-plan the middleware attachment point.

---

**End of Example**
