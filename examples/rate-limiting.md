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
- Add `express-rate-limit` with a Redis store so limits hold across instances. Apply only to the login route. Thresholds: 5 attempts per 15 minutes per IP (check latest package versions on the registry before pinning).

### Todo List
1. `package.json` - add `express-rate-limit` and `rate-limit-redis` (versions from registry).
2. `src/middleware/rateLimiter.ts` - create `loginLimiter` using the existing Redis client, standard headers on, 429 handler.
3. `src/api/auth.ts:23` - apply `loginLimiter` to the login route only.
4. `tests/api/auth.test.ts` - add test: 6th failed attempt returns 429.

### Risks
- Redis unavailability at runtime must not take the login path down (fail-open vs fail-closed decision).
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
  "version": "3.5.0",
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

### Blocked Items
- None.

### Next Phase
- Enter Verifier.
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
| Edge cases | warn | Redis outage behavior unspecified (store throws -> 500 on login) |
| Security | pass | security branch run: no secrets, no injection, headers on, auth flow intact |
| Side effects | pass | no other route consumes the middleware |

### Commands Run
- `npm run lint` - passed.
- `npm run typecheck` - passed.
- `npm test -- auth.test.ts` - passed (6 tests).

### Failed or Skipped Commands
- None.

### Issue Details
- `src/middleware/rateLimiter.ts` - if Redis is down, the store throws and login returns 500. Non-blocking, but the fail-open/fail-closed choice should be explicit.

### Suggested Fix
- Optional follow-up: wrap store commands to fail open with a logged warning, or document fail-closed as intended.

### Consolidation Candidates
- None. The Redis fail-closed trade-off is a residual risk, not durable knowledge; the OAuth exemption is derivable from the route structure (never-capture: code-derivable facts).

### Review Result
- Pass and enter Phase 4 (warning recorded as residual risk).

### Change Summary
- Files modified: 3, files created: 1 (from `git diff --stat`)
- Lines changed: +52 -1 (from `git diff --stat`)
- Scope: login rate limiting with Redis-backed store
```

## Phase 4: Completion

```markdown
## 变更摘要
- 为登录接口添加基于 Redis 的分布式限流（每 IP 15 分钟 5 次），OAuth 回调不受影响。

## 涉及文件
- `package.json` (Modified): 新增 express-rate-limit 与 rate-limit-redis。
- `src/middleware/rateLimiter.ts` (Added): loginLimiter 中间件。
- `src/api/auth.ts` (Modified): 登录路由挂载限流中间件。
- `tests/api/auth.test.ts` (Modified): 新增 429 限流测试。

## 验证结果
- ✅ `npm run lint` passed
- ✅ `npm run typecheck` passed
- ✅ `npm test -- auth.test.ts` passed (6 passing)

## 失败或未执行的命令
- None.

## 剩余风险
- Redis 不可用时登录路径返回 500（fail-closed）；如需 fail-open 需追加处理。

## 后续建议
- 评估按账号维度的二级限流以覆盖分布式攻击源。
```

State cleanup: archive `.tav/state.json` to `.tav/archive/` (it belongs to this completed workflow).

## Alternative Scenarios

**Redis not available in the project** - Thinker plans an in-memory limiter instead and documents the single-instance limitation in the todo list.

**Verifier finds OAuth affected** - `Compatibility: fail`, return to Actor with one item: remove the middleware from the OAuth route.

**Actor finds class-based controllers instead of Express routes** - structural mismatch with the plan; stop, return to Thinker with the evidence, re-plan the middleware attachment point.

---

**End of Example**
