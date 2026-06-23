---
name: tav-workflow
description: Use when implementing scoped code changes, bug fixes, configuration updates, feature adjustments, or local refactors that need analysis, execution, and verification. Do not use for full-project rewrites, migrations, or large transformations that need spec-driven planning first.
version: 3.0.0
---

# TAV Workflow — Three-Role Collaboration

Structured three-role collaboration ensuring every change has independent perspectives for thinking, execution, and verification. This workflow uses automated agent orchestration with state persistence and quality gates.

**TAV = Think-Act-Verify**

## Trigger Conditions

**Must use this Skill when:**
- Code modifications (bug fixes, feature adjustments, refactoring)
- New feature development
- Configuration changes
- User says "help me change", "fix this", "implement a feature"

**Use spec-driven-develop instead when:**
- The task is a full-project rewrite, migration, framework/language rebuild, architecture overhaul, or multi-phase transformation
- The user asks for “spec-driven”, “rewrite”, “migrate”, “overhaul”, “重写”, “迁移”, “重构”, or “大规模” work
- Success requires project-wide analysis and a task plan before any coding begins

**No need to use when:**
- Pure information queries ("what does this code do")
- Simple file reads
- Single-file operations with clear instructions requiring no analysis

### TAV vs Spec-Driven

| Need | Use |
|------|-----|
| Scoped bug fix, feature tweak, config change | `tav-workflow` |
| Local refactor with known target | `tav-workflow` |
| Project rewrite, migration, rebuild, architecture overhaul | `spec-driven-develop` |
| Need docs/analysis/plan/progress before coding | `spec-driven-develop` |

---

## Before You Begin: Continuity Check

**CRITICAL**: Before starting any phase, check if `.tav/state.json` exists in the project root.

- If it **exists**: Read it immediately. You are resuming an in-progress workflow. Identify which phase you are in, what has been completed, and continue from the exact point where the previous conversation left off. Do NOT restart from Phase 1.
- If it **does not exist**: This is a fresh start. Proceed to Phase 1.

After loading state, populate the platform's native task tracking tool (TodoWrite) with pending tasks from the current phase. This gives the user real-time visual progress.

---

## Configuration

| Setting | Default | Purpose |
|:--------|:--------|:--------|
| State file | `.tav/state.json` | Cross-conversation state persistence |
| Max Thinker rounds | 3 | Clarification limit before escalation |
| Max Actor-Verifier loops | 3 | Fix iteration limit before re-analysis |
| Token budget - Thinker | 10,000 | Analysis phase token limit |
| Token budget - Actor | 8,000 | Execution phase token limit |
| Token budget - Verifier | 5,000 | Review phase token limit |
| Quality gate | Enabled | Automated checks after Actor phase |

---

## Role Definitions

### Thinker (Analyst)

**Responsibilities:** Requirement breakdown, code reading, evidence gathering, execution planning

**Core Principles:**
- Read code first, conclude later — never assume without evidence
- Read all relevant files in parallel to reduce rounds
- Every conclusion must be backed by code location

**Tools:**
- `Read` — Read relevant code files
- `Grep` — Search keywords for positioning
- `Glob` — Find related files
- `Bash` — Run diagnostic commands (git status, git log, etc.)

**Output Requirements:**
- Evidence summary: Files read and key findings
- Todo-list: Each item must include `file:line - specific action`
- Risk notes: Identify potential side effects or compatibility issues

---

### Actor (Executor)

**Responsibilities:** Execute minimal changes strictly following the Todo-list

**Core Principles:**
- Minimal change principle — only modify what's directly required
- No extra refactoring, comments, or formatting changes
- Each Edit/Write changes only one logical point
- Maintain existing code style consistency

**Tools:**
- `Edit` — Modify existing files (preferred)
- `Write` — Create new files (when necessary)
- No additional exploration unless the plan is incomplete; if incomplete, stop and return to Thinker

**Output Requirements:**
- Concisely report each Edit/Write result
- Stop immediately and return to Thinker phase if Todo-list doesn't cover encountered situations

---

### Verifier (Reviewer)

**Responsibilities:** Validate correctness, check side effects, confirm completion

**Core Principles:**
- Independent verification — never assume Actor did it right
- Global perspective — check impact on surrounding code
- Security review — focus on edge cases and exception paths

**Tools:**
- `Read` — Read modified file fragments
- `Grep` — Check for missed references
- `Bash` — Run tests, type checks

**Review Checklist:**
1. [ ] Does the change implement what Thinker analyzed
2. [ ] Any new syntax or type errors introduced
3. [ ] Compatibility with other code affected
4. [ ] Edge cases handled correctly
5. [ ] Any associated changes missed
6. [ ] Security vulnerabilities introduced
7. [ ] Tests pass (if applicable)
8. [ ] Performance impact acceptable

**Output Requirements:**
- Pass: Concisely confirm "review passed"
- Fail: Clearly state issue + suggested fix, return to Actor phase

---

## Execution Flow

The agent names in examples are conceptual role aliases. Map them to the current platform's available agents/tools before execution. If a named agent or tool is unavailable, use the closest equivalent while preserving the role separation: Thinker analyzes, Actor changes, Verifier checks.

### Phase 1: Thinker — Analysis & Design

**Implementation via Agent:**

```typescript
Agent({
  subagent_type: "planner", // conceptual: use available planning/explore agent
  description: "TAV Thinker - Analyze requirements",
  prompt: `You are the Thinker role in the TAV workflow.

**Your Task:**
Analyze the following requirement and produce a detailed execution plan.

**Requirement:**
${userRequest}

**Your Responsibilities:**
1. Read all relevant code files (use parallel Read calls)
2. Search for related symbols and dependencies (use Grep)
3. Identify all files that need modification
4. Create a precise Todo-list with file:line specificity
5. Document risks and potential side effects

**Output Format:**

### Evidence Gathered
- Read file: \`path/to/file:line-range\` — what you found
- Search references: \`symbolName\` called in N places
- Related dependencies: list of related files/modules

### Analysis Conclusion
<2-3 sentences summarizing core findings>

### Todo-list
1. \`file/path:line\` — specific action to take
2. \`file/path:line\` — specific action to take
...

### Risk Notes
- List potential issues, side effects, or compatibility concerns

**Constraints:**
- Every conclusion must cite file:line evidence
- Read files in parallel when possible
- Token budget: 10,000 tokens max
- If requirements unclear, ask max 3 clarifying questions
`
})
```

**State Update:**
After Thinker completes, update `.tav/state.json`:
```json
{
  "currentPhase": "Actor",
  "phases": {
    "Thinker": {
      "status": "completed",
      "output": { /* thinker output */ },
      "timestamp": "2026-05-19T08:30:00Z",
      "tokenUsage": 5234
    }
  }
}
```

**TodoWrite Integration:**
Write todos to native task tracker:
```typescript
TodoWrite({
  todos: thinkerOutput.todoList.map(item => ({
    content: item.description,
    status: "todo",
    priority: item.risk === "high" ? "high" : "medium"
  }))
})
```

---

### Phase 2: Actor — Execute Changes

**Implementation via Agent:**

```typescript
Agent({
  subagent_type: "general-purpose", // conceptual: use available coding/execution agent
  mode: "acceptEdits", // optional if the platform supports it
  description: "TAV Actor - Execute changes",
  prompt: `You are the Actor role in the TAV workflow.

**Your Task:**
Execute ONLY the following todo items. Make minimal changes.

**Todo-list:**
${JSON.stringify(thinkerOutput.todoList, null, 2)}

**Your Responsibilities:**
1. Execute each todo item in order
2. Use Edit for existing files, Write for new files
3. Make ONLY the changes specified — no refactoring, no extra comments
4. Match existing code style exactly
5. Stop immediately if you encounter a situation not covered by the todo-list

**Constraints:**
- Minimal change principle — touch only what's required
- No exploration (no Read/Grep unless absolutely necessary)
- Token budget: 8,000 tokens max
- If todo-list incomplete, stop and return to Thinker

**Output Format:**

### Progress
1. ✓ \`file:line\` — what you did
2. ✓ \`file:line\` — what you did
...

### Details
- Edit N: brief description of change
- Write N: brief description of new file

**If you encounter an issue:**
Stop immediately and report:
- Which todo item you were on
- What situation you encountered
- Why the todo-list doesn't cover it
`
})
```

**State Update:**
After Actor completes, update state:
```json
{
  "currentPhase": "Verifier",
  "phases": {
    "Actor": {
      "status": "completed",
      "completedItems": [1, 2, 3],
      "timestamp": "2026-05-19T08:45:00Z",
      "tokenUsage": 3421
    }
  }
}
```

**Quality Gate (Automated):**
Run automated checks after Actor phase:
```typescript
// Run linter
Bash({ command: "npm run lint" })

// Run type checker
Bash({ command: "npm run type-check" })

// If checks fail, return to Actor with error output
```

---

### Phase 3: Verifier — Review & Validate

**Implementation via Agent:**

```typescript
Agent({
  subagent_type: "reviewer", // conceptual: use available review/verification agent
  description: "TAV Verifier - Review changes",
  prompt: `You are the Verifier role in the TAV workflow.

**Your Task:**
Independently verify the changes made by Actor against the original analysis.

**Original Analysis:**
${JSON.stringify(thinkerOutput, null, 2)}

**Changes Made:**
${JSON.stringify(actorOutput, null, 2)}

**Your Responsibilities:**
1. Read the modified files (use targeted reads with offset/limit)
2. Check for syntax/type errors
3. Verify compatibility with surrounding code
4. Check for security vulnerabilities
5. Grep for missed references
6. Run tests if applicable

**Review Checklist:**
- [ ] Does the change implement what Thinker analyzed
- [ ] Any new syntax or type errors introduced
- [ ] Compatibility with other code affected
- [ ] Edge cases handled correctly
- [ ] Any associated changes missed
- [ ] Security vulnerabilities introduced
- [ ] Tests pass (if applicable)
- [ ] Performance impact acceptable

**Constraints:**
- Independent verification — don't trust Actor blindly
- Token budget: 5,000 tokens max
- Read only changed sections (use offset/limit)
- Run tests once at end, not per-edit

**Output Format:**

### Verification Items
| Check | Status | Notes |
|-------|--------|-------|
| Requirement met | ✓/✗/⚠ | ... |
| Syntax correct | ✓/✗/⚠ | ... |
...

**If issues found:**
### Issue Details
- \`file:line\` — description of issue

### Suggested Fix
- Specific action to fix the issue

**If all checks pass:**
### Review Result
All checks passed, changes correct and complete.
`
})
```

**State Update:**
After Verifier completes:
```json
{
  "currentPhase": "Complete",
  "phases": {
    "Verifier": {
      "status": "completed",
      "result": "pass",
      "timestamp": "2026-05-19T09:00:00Z",
      "tokenUsage": 2134
    }
  },
  "totalTokenUsage": 10789,
  "iterations": 1
}
```

---

### Phase 4: Complete

```
**[TAV Workflow - Complete]**

### Summary
- Files modified: 3
- Lines changed: +45 -12
- Phases completed: Thinker → Actor → Verifier
- Total iterations: 1
- Token usage: 10,789

### Changes
1. src/api/user.ts — Added pagination validation
2. src/api/user.ts — Modified query with LIMIT
3. src/types/user.ts — Updated return type

✓ Task complete
```

**Cleanup:**
Archive state file:
```bash
mv .tav/state.json .tav/archive/state-$(date +%Y%m%d-%H%M%S).json
```

---

## Error Recovery Protocol

### Recovery Decision Tree

```
Error Type → Detection Phase → Action → Fallback
──────────────────────────────────────────────────
Unclear requirements
  → Thinker
  → Ask user (max 3 questions)
  → If still unclear: abort with summary

Incomplete todo-list
  → Actor
  → Return to Thinker with context
  → Thinker supplements (max 2 rounds)

Verification failure
  → Verifier
  → Return to Actor with fix instructions
  → Actor fixes (max 3 attempts)
  → If still failing: return to Thinker

Critical security issue
  → Verifier
  → Block and report affected files
  → Require explicit user approval before any rollback or destructive action

Test failure
  → Verifier
  → Return to Actor with test output
  → Actor fixes (max 3 attempts)
  → If still failing: escalate to Thinker

Token budget exceeded
  → Any phase
  → Save state and pause
  → Report to user with summary
```

### Retry Limits

| Scenario | Max Attempts | Escalation |
|----------|--------------|------------|
| Thinker clarification | 3 rounds | Abort with summary |
| Actor-Verifier loop | 3 iterations | Return to Thinker |
| Thinker re-analysis | 2 rounds | Escalate to user |
| Total workflow iterations | 5 | Abort with diagnostic |

### State Rollback

If critical issue found:
```typescript
// Read previous state
const prevState = JSON.parse(fs.readFileSync('.tav/archive/state-previous.json'))

// Rollback changes only after explicit user approval.
// Use the platform's safe non-destructive workflow where available.

// Restore state
fs.writeFileSync('.tav/state.json', JSON.stringify(prevState))
```

---

## Performance Optimization

### Token Budget per Phase

| Phase | Target | Max | Notes |
|-------|--------|-----|-------|
| Thinker | 5,000 | 10,000 | Parallel reads, batch Grep |
| Actor | 3,000 | 8,000 | One-pass edits, no re-reads |
| Verifier | 2,000 | 5,000 | Targeted reads only |
| **Total** | **10,000** | **23,000** | Per iteration |

### Efficiency Rules

**Thinker Phase:**
- ✓ Read all files in ONE parallel call: `Read([file1, file2, file3])`
- ✓ Use Grep with `output_mode: "files_with_matches"` first
- ✓ Only read full content for confirmed relevant files
- ✗ Don't read the same file twice
- ✗ Don't grep for obvious symbols

**Actor Phase:**
- ✓ Never re-read files you just edited (trust Edit tool)
- ✓ Batch related edits in same file
- ✓ Use Edit over Write for existing files
- ✗ Don't explore code (that's Thinker's job)
- ✗ Don't add comments unless required

**Verifier Phase:**
- ✓ Read only changed sections (use `offset` + `limit`)
- ✓ Grep for references instead of reading entire files
- ✓ Run tests once at end, not per-edit
- ✗ Don't re-analyze (trust Thinker's analysis)
- ✗ Don't re-read unchanged files

---

## Quality Gates

### Phase Completion Criteria

**Thinker Phase:**
- [ ] All relevant files identified and read
- [ ] Todo-list has file:line specificity
- [ ] Risks documented
- [ ] No assumptions without evidence
- [ ] Token usage < 10,000

**Actor Phase:**
- [ ] All todo items completed
- [ ] No extra changes made
- [ ] Code compiles/lints
- [ ] Style matches existing code
- [ ] Token usage < 8,000

**Verifier Phase:**
- [ ] All checklist items reviewed
- [ ] Tests pass (if applicable)
- [ ] No new errors introduced
- [ ] Side effects checked
- [ ] Token usage < 5,000

### Automated Checks

Run after Actor phase (before Verifier):

```typescript
// Lint check
const lintResult = Bash({ command: "npm run lint" })
if (lintResult.exitCode !== 0) {
  return { phase: "Actor", error: "Lint failed", output: lintResult.stderr }
}

// Type check
const typeResult = Bash({ command: "npm run type-check" })
if (typeResult.exitCode !== 0) {
  return { phase: "Actor", error: "Type check failed", output: typeResult.stderr }
}

// Unit tests (if applicable)
const testResult = Bash({ command: "npm test -- --changed" })
if (testResult.exitCode !== 0) {
  return { phase: "Verifier", error: "Tests failed", output: testResult.stderr }
}
```

### Quality Metrics

Track in state file:
```json
{
  "metrics": {
    "filesModified": 3,
    "linesAdded": 45,
    "linesRemoved": 12,
    "tokenUsage": 10789,
    "iterations": 1,
    "duration": "15m 30s",
    "qualityGates": {
      "lint": "pass",
      "typeCheck": "pass",
      "tests": "pass"
    }
  }
}
```

---

## Integration with Other Skills

### Pattern 1: Deep-Discuss → TAV

When requirements are unclear:

```typescript
// Step 1: Clarify with deep-discuss
const discussion = Skill({ 
  skill: "deep-discuss", 
  args: userRequest 
})

// Step 2: Use clarified requirements in TAV
const clarifiedReq = discussion.conclusion
tavWorkflow(clarifiedReq)
```

### Pattern 2: TAV → Review

After TAV completion:

```typescript
// TAV completes changes
tavWorkflow.complete()

// Trigger PR-level review
Skill({ skill: "review" })
```

### Pattern 3: Spec-Dev → TAV (per module)

For large-scale projects:

```typescript
// Spec-dev generates module tasks
const tasks = Skill({ skill: "spec-dev" })

// Apply TAV to each module
for (const module of tasks.modules) {
  tavWorkflow({
    scope: module.name,
    requirement: module.description,
    todoList: module.tasks
  })
}
```

### Pattern 4: TAV → Smart-Commit

After successful completion:

```typescript
// TAV completes
tavWorkflow.complete()

// Create commit with quality gates
Skill({ skill: "smart-commit" })
```

---

## State Management

### State File Structure: `.tav/state.json`

```json
{
  "version": "3.0.0",
  "taskId": "tav-20260519-083000",
  "userRequest": "Add rate limiting to login API",
  "currentPhase": "Actor",
  "startTime": "2026-05-19T08:30:00Z",
  "lastUpdate": "2026-05-19T08:45:00Z",
  
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
            "finding": "login endpoint found, no rate limiting"
          }
        ],
        "todoList": [
          {
            "id": 1,
            "file": "package.json",
            "line": null,
            "action": "Add express-rate-limit@6.7.0",
            "risk": "low"
          },
          {
            "id": 2,
            "file": "src/middleware/rateLimiter.ts",
            "line": null,
            "action": "Create rate limiter config",
            "risk": "medium"
          }
        ],
        "risks": [
          "Redis connection must be available",
          "Rate limit headers should be documented"
        ]
      }
    },
    
    "Actor": {
      "status": "in-progress",
      "startTime": "2026-05-19T08:35:00Z",
      "tokenUsage": 2100,
      "completedItems": [1, 2],
      "pendingItems": [3, 4],
      "changes": [
        {
          "type": "edit",
          "file": "package.json",
          "description": "Added express-rate-limit dependency"
        },
        {
          "type": "write",
          "file": "src/middleware/rateLimiter.ts",
          "description": "Created rate limiter with Redis store"
        }
      ]
    },
    
    "Verifier": {
      "status": "pending"
    }
  },
  
  "iterations": 1,
  "retryCount": {
    "thinkerClarifications": 0,
    "actorVerifierLoops": 0,
    "thinkerReanalysis": 0
  },
  
  "metrics": {
    "totalTokenUsage": 7334,
    "filesModified": 2,
    "linesAdded": 35,
    "linesRemoved": 0
  }
}
```

### State Operations

**Initialize State:**
```typescript
function initializeState(userRequest: string) {
  const state = {
    version: "3.0.0",
    taskId: `tav-${Date.now()}`,
    userRequest,
    currentPhase: "Thinker",
    startTime: new Date().toISOString(),
    phases: {
      Thinker: { status: "in-progress" },
      Actor: { status: "pending" },
      Verifier: { status: "pending" }
    },
    iterations: 1,
    retryCount: {},
    metrics: {}
  }
  
  fs.mkdirSync('.tav', { recursive: true })
  fs.writeFileSync('.tav/state.json', JSON.stringify(state, null, 2))
  return state
}
```

**Load State:**
```typescript
function loadState() {
  if (!fs.existsSync('.tav/state.json')) {
    return null
  }
  return JSON.parse(fs.readFileSync('.tav/state.json', 'utf-8'))
}
```

**Update State:**
```typescript
function updateState(updates: Partial<State>) {
  const state = loadState()
  const newState = {
    ...state,
    ...updates,
    lastUpdate: new Date().toISOString()
  }
  fs.writeFileSync('.tav/state.json', JSON.stringify(newState, null, 2))
  return newState
}
```

**Archive State:**
```typescript
function archiveState() {
  const state = loadState()
  fs.mkdirSync('.tav/archive', { recursive: true })
  const archivePath = `.tav/archive/state-${state.taskId}.json`
  fs.writeFileSync(archivePath, JSON.stringify(state, null, 2))
  fs.unlinkSync('.tav/state.json')
}
```

---

## Complete Example

See `examples/rate-limiting.md` for a full walkthrough of adding API rate limiting using the TAV workflow.

---

## Best Practices

### Thinker's Efficiency Principles
- Parallel reads: Read all relevant files in one Read call
- Precise positioning: Each Todo item corresponds to specific file:line
- Early risk identification: Mark potential pitfalls during analysis
- Evidence-based: Every conclusion cites file:line

### Actor's Restraint Principles
- No extra changes: Even if seeing "optimizable code", don't touch
- No added comments: Unless user explicitly requests
- Style consistency: Match existing code's naming, formatting
- Trust the plan: Don't explore, just execute

### Verifier's Independence Principles
- Don't trust Actor's execution: Must verify personally
- Focus on global impact: Not just changed lines, but surrounding code
- Verify testability: Can related tests run after changes
- Security first: Check for vulnerabilities before approving

---

## Troubleshooting

### Common Issues

**Issue: Thinker can't find relevant files**
- Solution: Use broader Grep patterns, check file naming conventions
- Fallback: Ask user for file locations

**Issue: Actor encounters unexpected code structure**
- Solution: Stop and return to Thinker for re-analysis
- Don't try to improvise — incomplete todo-list is a Thinker problem

**Issue: Verifier finds breaking changes**
- Solution: Return to Actor with specific fix instructions
- If fixes fail 3 times, return to Thinker for new approach

**Issue: Token budget exceeded**
- Solution: Save state and pause, report to user
- Resume in next conversation from saved state

**Issue: Quality gates fail**
- Solution: Return to Actor with error output
- Fix the specific errors, don't refactor

---

## References

- `examples/rate-limiting.md` — Complete walkthrough example
- `examples/bug-fix.md` — Bug fix example
- `examples/refactoring.md` — Refactoring example
- `references/templates/state.json` — State file template
- `references/templates/thinker-output.md` — Thinker output template
- `references/templates/actor-output.md` — Actor output template
- `references/templates/verifier-output.md` — Verifier output template

---

## Version History

### 3.0.0 (2026-05-19)
- Added automated agent orchestration
- Added state persistence for cross-conversation continuity
- Added native tool integration (todo/progress tools, platform-dependent)
- Added quality gates and automated checks
- Added performance optimization guidelines
- Added error recovery protocol with retry limits
- Added complete examples
- Added skill composition patterns

### 2.0.0 (Previous)
- Initial three-role workflow definition
- Basic phase descriptions
- Manual execution model

---

**End of TAV Workflow Skill**
