# Complete Example: Add API Rate Limiting

This example demonstrates the full TAV workflow for adding rate limiting to a login API endpoint.

The agent names below are conceptual role aliases. Replace them with the current platform's available planning, execution, and verification agents.

## User Request

"Add rate limiting to the user login API to prevent brute force attacks"

## Initial State Check

```bash
$ ls .tav/state.json
# File not found — fresh start
```

## Phase 1: Thinker — Analysis

### Agent Invocation

```typescript
Agent({
  subagent_type: "planner",
  description: "TAV Thinker - Analyze rate limiting requirement",
  prompt: `You are the Thinker role in the TAV workflow.

**Your Task:**
Analyze the requirement to add rate limiting to the user login API.

**Requirement:**
Add rate limiting to the user login API to prevent brute force attacks

**Your Responsibilities:**
1. Find the login API endpoint
2. Identify the tech stack (Express, Fastify, etc.)
3. Check if Redis or similar is available for distributed rate limiting
4. Determine appropriate rate limit thresholds
5. Create a precise Todo-list

**Output Format:** [standard Thinker format]
`
})
```

### Thinker Output

```markdown
**[Thinker - Analysis]**
Phase 1 → Analyzing

### Evidence Gathered
- Read file: `src/api/auth.ts:23-45` — Found login endpoint using Express.js
  ```typescript
  router.post('/login', async (req, res) => {
    const { email, password } = req.body
    // ... authentication logic
  })
  ```
- Read file: `package.json:15-30` — Express 4.18.2 installed, no rate limiting package
- Read file: `src/config/redis.ts:1-20` — Redis client already configured and available
- Search references: `loginUser` called in 3 places:
  - `src/api/auth.ts:23` — main endpoint
  - `src/api/auth.ts:67` — OAuth callback (different flow)
  - `tests/api/auth.test.ts:45` — test file
- Related dependencies: `src/middleware/` directory exists with other middleware

### Analysis Conclusion
The login endpoint is an Express.js route with no rate limiting. Redis is already configured and available for distributed rate limiting. We should use `express-rate-limit` with `rate-limit-redis` store. Standard recommendation: 5 attempts per 15 minutes per IP address.

### Todo-list
1. `package.json` — Add `express-rate-limit@6.7.0` and `rate-limit-redis@3.0.1`
2. `src/middleware/rateLimiter.ts` — Create new file with rate limiter configuration
3. `src/api/auth.ts:23` — Apply `loginLimiter` middleware to login route
4. `src/api/auth.ts:30` — Add error handling for rate limit exceeded (429 response)
5. `tests/api/auth.test.ts` — Add test for rate limiting behavior

### Risk Notes
- Redis connection must be available at runtime (Verifier should check error handling)
- Rate limit should only apply to login endpoint, not OAuth flow
- Need to ensure rate limit headers are sent (X-RateLimit-Limit, X-RateLimit-Remaining)
- Consider whether to rate limit by IP or by email (currently using IP)
```

### State File Created

`.tav/state.json`:
```json
{
  "version": "3.1.0",
  "taskId": "tav-20260519-083000",
  "userRequest": "Add rate limiting to the user login API to prevent brute force attacks",
  "current_phase": "Actor",
  "startTime": "2026-05-19T08:30:00Z",
  "lastUpdate": "2026-05-19T08:35:00Z",
  
  "phases": {
    "Thinker": {
      "status": "completed",
      "startTime": "2026-05-19T08:30:00Z",
      "endTime": "2026-05-19T08:35:00Z",
      "tokenUsage": 5234,
      "output": {
        "evidence": [
          {
            "file": "src/api/auth.ts",
            "lines": "23-45",
            "finding": "Express.js login endpoint, no rate limiting"
          },
          {
            "file": "src/config/redis.ts",
            "lines": "1-20",
            "finding": "Redis client configured and available"
          }
        ],
        "todoList": [
          {
            "id": 1,
            "file": "package.json",
            "line": null,
            "action": "Add express-rate-limit@6.7.0 and rate-limit-redis@3.0.1",
            "risk": "low"
          },
          {
            "id": 2,
            "file": "src/middleware/rateLimiter.ts",
            "line": null,
            "action": "Create rate limiter configuration",
            "risk": "medium"
          },
          {
            "id": 3,
            "file": "src/api/auth.ts",
            "line": 23,
            "action": "Apply loginLimiter middleware",
            "risk": "low"
          },
          {
            "id": 4,
            "file": "src/api/auth.ts",
            "line": 30,
            "action": "Add 429 error handling",
            "risk": "low"
          },
          {
            "id": 5,
            "file": "tests/api/auth.test.ts",
            "line": null,
            "action": "Add rate limiting test",
            "risk": "low"
          }
        ],
        "risks": [
          "Redis connection must be available at runtime",
          "Rate limit should only apply to login, not OAuth",
          "Rate limit headers should be sent",
          "Consider IP vs email-based rate limiting"
        ]
      }
    },
    "Actor": {
      "status": "pending"
    },
    "Verifier": {
      "status": "pending"
    }
  },
  
  "iterations": 1,
  "retryCount": {
    "thinkerClarifications": 0,
    "actorVerifierLoops": 0
  },
  
  "metrics": {
    "totalTokenUsage": 5234
  }
}
```

### Native Task Tracking Integration

```typescript
TaskCreate({
  subject: "Implement login rate limiting",
  description: "Track TAV Actor tasks generated by the Thinker phase.",
  activeForm: "Implementing login rate limiting"
})
```

---

## Phase 2: Actor — Execution

### Agent Invocation

```typescript
Agent({
  subagent_type: "general-purpose",
  mode: "acceptEdits",
  description: "TAV Actor - Execute rate limiting changes",
  prompt: `You are the Actor role in the TAV workflow.

**Your Task:**
Execute ONLY the following todo items. Make minimal changes.

**Todo-list:**
${JSON.stringify(thinkerOutput.todoList, null, 2)}

**Constraints:**
- Minimal change principle
- No refactoring
- Match existing code style
- Stop if todo-list incomplete
`
})
```

### Actor Output

```markdown
**[Actor - Execution]**
Phase 2 → Executing

### Progress
1. ✓ `package.json` — Added dependencies
2. ✓ `src/middleware/rateLimiter.ts` — Created rate limiter
3. ✓ `src/api/auth.ts:23` — Applied middleware
4. ✓ `src/api/auth.ts:30` — Added error handling
5. ✓ `tests/api/auth.test.ts` — Added test

### Details

**Edit 1: package.json**
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "express-rate-limit": "^6.7.0",
    "rate-limit-redis": "^3.0.1",
    "redis": "^4.6.5"
  }
}
```

**Write 1: src/middleware/rateLimiter.ts**
```typescript
import rateLimit from 'express-rate-limit'
import RedisStore from 'rate-limit-redis'
import { redisClient } from '../config/redis'

export const loginLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:login:'
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts
  message: 'Too many login attempts, please try again later',
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

**Edit 2: src/api/auth.ts**
```typescript
import { loginLimiter } from '../middleware/rateLimiter'

// Before: router.post('/login', async (req, res) => {
// After:
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { email, password } = req.body
    // ... existing authentication logic
  } catch (error) {
    if (error.name === 'RateLimitError') {
      return res.status(429).json({
        success: false,
        error: 'Too many login attempts'
      })
    }
    // ... existing error handling
  }
})
```

**Edit 3: tests/api/auth.test.ts**
```typescript
describe('POST /login - Rate Limiting', () => {
  it('should block after 5 failed attempts', async () => {
    // Make 5 requests
    for (let i = 0; i < 5; i++) {
      await request(app)
        .post('/api/auth/login')
        .send({ email: 'test@example.com', password: 'wrong' })
    }
    
    // 6th request should be rate limited
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'wrong' })
    
    expect(response.status).toBe(429)
    expect(response.body.error).toContain('Too many login attempts')
  })
})
```

→ Enter Phase 3: Review
```

### State Update

`.tav/state.json`:
```json
{
  "current_phase": "Verifier",
  "phases": {
    "Actor": {
      "status": "completed",
      "startTime": "2026-05-19T08:35:00Z",
      "endTime": "2026-05-19T08:45:00Z",
      "tokenUsage": 3421,
      "completedItems": [1, 2, 3, 4, 5],
      "changes": [
        {
          "type": "edit",
          "file": "package.json",
          "description": "Added express-rate-limit and rate-limit-redis"
        },
        {
          "type": "write",
          "file": "src/middleware/rateLimiter.ts",
          "description": "Created rate limiter with Redis store"
        },
        {
          "type": "edit",
          "file": "src/api/auth.ts",
          "description": "Applied loginLimiter middleware and error handling"
        },
        {
          "type": "edit",
          "file": "tests/api/auth.test.ts",
          "description": "Added rate limiting test"
        }
      ]
    }
  },
  "metrics": {
    "totalTokenUsage": 8655,
    "filesModified": 3,
    "filesCreated": 1,
    "linesAdded": 52,
    "linesRemoved": 1
  }
}
```

### Quality Gate (Automated)

```bash
# Run linter
$ npm run lint
✓ All files pass linting

# Run type checker
$ npm run type-check
✓ No type errors

# Quality gate: PASS
```

---

## Phase 3: Verifier — Review

### Agent Invocation

```typescript
Agent({
  subagent_type: "reviewer",
  description: "TAV Verifier - Review rate limiting implementation",
  prompt: `You are the Verifier role in the TAV workflow.

**Your Task:**
Independently verify the rate limiting implementation.

**Original Analysis:**
${JSON.stringify(thinkerOutput, null, 2)}

**Changes Made:**
${JSON.stringify(actorOutput, null, 2)}

**Review Checklist:** [standard checklist]
`
})
```

### Verifier Output

```markdown
**[Verifier - Review]**
Phase 3 → Reviewing

### Verification Items

| Check | Status | Notes |
|-------|--------|-------|
| Requirement met | ✓ | Rate limiting correctly implemented |
| Syntax correct | ✓ | No syntax errors |
| Type safe | ✓ | TypeScript types correct |
| Redis connection | ⚠ | Error handling exists but not tested |
| Rate limit headers | ✓ | standardHeaders: true configured |
| Only login endpoint | ✓ | OAuth endpoint not affected |
| Tests added | ✓ | Rate limit test added |
| Security | ✓ | No vulnerabilities introduced |

### Detailed Verification

**1. Read modified files:**
- `src/middleware/rateLimiter.ts:1-20` — Configuration looks correct
- `src/api/auth.ts:23` — Middleware applied correctly
- `src/api/auth.ts:30-35` — Error handling added

**2. Grep for references:**
- `loginLimiter` used only in `src/api/auth.ts:23` ✓
- OAuth endpoint at line 67 not affected ✓

**3. Run tests:**
```bash
$ npm test -- auth.test.ts
✓ POST /login - Rate Limiting - should block after 5 failed attempts (234ms)
✓ All existing tests pass
```

**4. Check Redis connection handling:**
- RedisStore will throw if connection fails
- Error is caught by Express error handler
- ⚠ Warning: Should add explicit Redis connection check

### Issue Details

**Minor Issue (Non-blocking):**
- `src/middleware/rateLimiter.ts` — No explicit Redis connection error handling
- If Redis is down, rate limiting will fail silently or throw unhandled error

### Suggested Enhancement (Optional)

Add Redis connection check:
```typescript
export const loginLimiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rl:login:',
    sendCommand: async (...args) => {
      try {
        return await redisClient.sendCommand(args)
      } catch (error) {
        console.error('Redis rate limit error:', error)
        // Fallback: allow request (fail open)
        return null
      }
    }
  }),
  // ... rest of config
})
```

### Review Result

**Status: PASS with minor warning**

All critical checks passed. The implementation is correct and secure. The Redis connection warning is a minor enhancement, not a blocker.

### Change Summary
- Files modified: 3
- Files created: 1
- Lines added: 52
- Lines removed: 1
- Scope: Login API rate limiting
- Security: No vulnerabilities
- Tests: Pass

✓ Task complete
```

### State Update

`.tav/state.json`:
```json
{
  "current_phase": "Complete",
  "phases": {
    "Verifier": {
      "status": "completed",
      "startTime": "2026-05-19T08:45:00Z",
      "endTime": "2026-05-19T08:50:00Z",
      "tokenUsage": 2134,
      "result": "pass",
      "warnings": [
        "Redis connection error handling could be improved"
      ]
    }
  },
  "endTime": "2026-05-19T08:50:00Z",
  "iterations": 1,
  "metrics": {
    "totalTokenUsage": 10789,
    "filesModified": 3,
    "filesCreated": 1,
    "linesAdded": 52,
    "linesRemoved": 1,
    "duration": "20m 0s",
    "qualityGates": {
      "lint": "pass",
      "typeCheck": "pass",
      "tests": "pass"
    }
  }
}
```

---

## Phase 4: Complete

```markdown
**[TAV Workflow - Complete]**

### Summary
✓ Rate limiting successfully added to login API

### Changes
1. package.json — Added express-rate-limit and rate-limit-redis
2. src/middleware/rateLimiter.ts — Created rate limiter (5 attempts/15min)
3. src/api/auth.ts — Applied middleware and error handling
4. tests/api/auth.test.ts — Added rate limiting test

### Metrics
- Files modified: 3
- Files created: 1
- Lines changed: +52 -1
- Phases: Thinker → Actor → Verifier
- Iterations: 1
- Token usage: 10,789
- Duration: 20 minutes

### Quality Gates
✓ Lint: Pass
✓ Type check: Pass
✓ Tests: Pass

### Notes
- Rate limit: 5 attempts per 15 minutes per IP
- Redis-backed for distributed rate limiting
- Rate limit headers included in response
- OAuth endpoint not affected

✓ Task complete
```

### Cleanup

```bash
# Archive state file
Archive `.tav/state.json` using the current platform's safe file operation after completion.

# State archived successfully
```

---

## Key Takeaways

### What Went Well

1. **Thinker Phase:**
   - Found all relevant files in parallel
   - Identified Redis availability
   - Created precise todo-list with file:line specificity
   - Documented risks upfront

2. **Actor Phase:**
   - Executed all todos without deviation
   - Matched existing code style
   - No extra refactoring
   - Quality gates passed

3. **Verifier Phase:**
   - Independent verification caught potential issue
   - Ran tests to confirm functionality
   - Checked security implications
   - Provided optional enhancement suggestion

### Efficiency Metrics

- **Single iteration:** No Actor-Verifier loops needed
- **Token efficiency:** 10,789 tokens (within budget)
- **Time efficiency:** 20 minutes total
- **Quality:** All automated checks passed

### State Persistence Benefits

If the conversation was interrupted:
- State file preserves all progress
- Can resume from any phase
- Todo-list preserved
- Metrics tracked

---

## Alternative Scenarios

### Scenario 1: Redis Not Available

If Thinker found no Redis:

```markdown
### Todo-list
1. `package.json` — Add express-rate-limit@6.7.0 only
2. `src/middleware/rateLimiter.ts` — Create in-memory rate limiter
3. `src/api/auth.ts:23` — Apply middleware
4. `README.md` — Document limitation (not distributed)
```

### Scenario 2: Verifier Finds Breaking Change

If Verifier found OAuth affected:

```markdown
### Issue Details
- `src/api/auth.ts:67` — OAuth endpoint also rate limited (incorrect)

### Suggested Fix
Return to Actor:
- `src/api/auth.ts:67` — Remove loginLimiter from OAuth route

→ Return to Phase 2: Fix OAuth endpoint
```

### Scenario 3: Actor Encounters Unexpected Structure

If Actor found different auth structure:

```markdown
**[Actor - Execution]**
Phase 2 → Interrupted

### Issue Found
While executing Todo item 3:
- `src/api/auth.ts` uses class-based controllers, not Express routes
- Todo-list assumes Express router pattern
- Need different middleware application approach

→ Return to Phase 1: Re-analyze auth structure
```

---

**End of Example**
