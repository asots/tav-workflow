# TAV Workflow Implementation Guide

This document provides implementation guidance for the TAV workflow system.

## Architecture Overview

```
User Request
    ↓
Continuity Check (.tav/state.json exists?)
    ↓
Phase 1: Thinker (Analysis)
    ↓
Phase 2: Actor (Execution)
    ↓
Quality Gates (Automated)
    ↓
Phase 3: Verifier (Review)
    ↓
Complete or Iterate
```

## State Management

### State File Location

`.tav/state.json` in project root

### State Lifecycle

1. **Initialize**: Create state when workflow starts
2. **Update**: Update state after each phase
3. **Load**: Load state when resuming
4. **Archive**: Move to `.tav/archive/` when complete

### State Schema

See `references/templates/state.json` for full schema.

Key fields:
- `currentPhase`: "Thinker" | "Actor" | "Verifier" | "Complete"
- `phases`: Object with status and output for each phase
- `iterations`: Number of Actor-Verifier loops
- `retryCount`: Tracks retry attempts for error recovery
- `metrics`: Token usage, files changed, etc.

## Agent Orchestration

### Phase 1: Thinker Agent

**Agent Type**: `planner` conceptually. Map to the current platform's available planning/explore agent.

**Responsibilities**:
- Read relevant code files
- Search for symbols and dependencies
- Create precise todo-list
- Document risks

**Prompt Template**:
```typescript
Agent({
  subagent_type: "planner",
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
[See references/templates/thinker-output.md]

**Constraints:**
- Every conclusion must cite file:line evidence
- Read files in parallel when possible
- Token budget: 10,000 tokens max
- If requirements unclear, ask max 3 clarifying questions
`
})
```

### Phase 2: Actor Agent

**Agent Type**: `general-purpose` conceptually. Map to the current platform's available coding/execution agent.

**Mode**: `acceptEdits` only if the platform supports it.

**Responsibilities**:
- Execute todo-list items
- Make minimal changes
- Stop if todo-list incomplete

**Prompt Template**:
```typescript
Agent({
  subagent_type: "general-purpose",
  mode: "acceptEdits",
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
[See references/templates/actor-output.md]
`
})
```

### Phase 3: Verifier Agent

**Agent Type**: `reviewer` conceptually. Map to the current platform's available review/verification agent.

**Responsibilities**:
- Verify changes independently
- Run tests
- Check for side effects
- Security review

**Prompt Template**:
```typescript
Agent({
  subagent_type: "reviewer",
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
[See references/templates/verifier-output.md]
`
})
```

## Quality Gates

### Automated Checks

Run after Actor phase, before Verifier:

```typescript
async function runQualityGates() {
  const results = {
    lint: false,
    typeCheck: false,
    tests: false
  }
  
  // Lint check
  try {
    await Bash({ command: "npm run lint" })
    results.lint = true
  } catch (error) {
    return { phase: "Actor", error: "Lint failed", output: error.stderr }
  }
  
  // Type check
  try {
    await Bash({ command: "npm run type-check" })
    results.typeCheck = true
  } catch (error) {
    return { phase: "Actor", error: "Type check failed", output: error.stderr }
  }
  
  // Unit tests (optional, only if applicable)
  try {
    await Bash({ command: "npm test -- --changed" })
    results.tests = true
  } catch (error) {
    // Tests failing goes to Verifier for analysis
    results.tests = false
  }
  
  return results
}
```

## Error Recovery

### Recovery Decision Tree

```typescript
function handleError(error: Error, phase: Phase, retryCount: RetryCount) {
  switch (error.type) {
    case "UnclearRequirements":
      if (retryCount.thinkerClarifications >= 3) {
        return { action: "abort", reason: "Max clarifications reached" }
      }
      return { action: "clarify", phase: "Thinker" }
    
    case "IncompleteTodoList":
      if (retryCount.thinkerReanalysis >= 2) {
        return { action: "escalate", reason: "Max re-analysis reached" }
      }
      return { action: "reanalyze", phase: "Thinker" }
    
    case "VerificationFailure":
      if (retryCount.actorVerifierLoops >= 3) {
        return { action: "reanalyze", phase: "Thinker" }
      }
      return { action: "fix", phase: "Actor" }
    
    case "CriticalSecurity":
      return { action: "block", reason: "Security issue requires user approval" }
    
    case "TokenBudgetExceeded":
      return { action: "pause", reason: "Save state and resume later" }
    
    default:
      return { action: "escalate", reason: "Unknown error type" }
  }
}
```

### Retry Limits

```typescript
const RETRY_LIMITS = {
  thinkerClarifications: 3,
  actorVerifierLoops: 3,
  thinkerReanalysis: 2,
  totalIterations: 5
}
```

## Native Tool Integration

This section uses conceptual helper names. Use the current platform's actual todo/progress tools. If only a native todo list is available, use that and keep `.tav/state.json` as the durable workflow state.

### TodoWrite Integration

```typescript
function syncTodosToNative(todoList: TodoItem[]) {
  TodoWrite({
    todos: todoList.map((item, index) => ({
      content: `${item.file}:${item.line} - ${item.action}`,
      status: "todo",
      priority: item.risk === "high" ? "high" : "medium",
      metadata: {
        phase: "Actor",
        order: index + 1,
        tavTaskId: item.id
      }
    }))
  })
}

function updateTodoStatus(todoId: string, status: "completed" | "in-progress") {
  // Use the platform's todo update mechanism if available.
  TodoUpdate({
    id: todoId,
    status: status
  })
}
```

### TaskCreate Integration

This section is optional and platform-specific. If the platform only provides a native todo list, use that instead and keep `.tav/state.json` as the durable workflow state.

```typescript
function createWorkflowTask(userRequest: string, taskId: string) {
  return TaskCreate({
    title: `TAV Workflow - ${userRequest.slice(0, 50)}`,
    description: `
Task ID: ${taskId}
Phase: Thinker
Progress: 0/0
Token usage: 0
    `,
    status: "in-progress"
  })
}

function updateWorkflowTask(taskId: string, state: State) {
  const phase = state.currentPhase
  const completedItems = state.phases.Actor?.completedItems?.length || 0
  const totalItems = state.phases.Thinker?.output?.todoList?.length || 0
  
  TaskUpdate({
    id: taskId,
    description: `
Task ID: ${state.taskId}
Phase: ${phase}
Progress: ${completedItems}/${totalItems}
Token usage: ${state.metrics.totalTokenUsage}
    `,
    status: phase === "Complete" ? "completed" : "in-progress"
  })
}
```

## Performance Optimization

### Token Budget Management

```typescript
const TOKEN_BUDGETS = {
  Thinker: { target: 5000, max: 10000 },
  Actor: { target: 3000, max: 8000 },
  Verifier: { target: 2000, max: 5000 }
}

function checkTokenBudget(phase: Phase, usage: number) {
  const budget = TOKEN_BUDGETS[phase]
  
  if (usage > budget.max) {
    throw new Error(`Token budget exceeded for ${phase}: ${usage} > ${budget.max}`)
  }
  
  if (usage > budget.target) {
    console.warn(`Token usage above target for ${phase}: ${usage} > ${budget.target}`)
  }
}
```

### Efficiency Rules

**Thinker Phase**:
- Use parallel Read calls: `Read([file1, file2, file3])`
- Use Grep with `output_mode: "files_with_matches"` first
- Only read full content for confirmed relevant files

**Actor Phase**:
- Never re-read files just edited (trust Edit tool)
- Batch related edits in same file
- Use Edit over Write for existing files

**Verifier Phase**:
- Read only changed sections (use `offset` + `limit`)
- Grep for references instead of reading entire files
- Run tests once at end, not per-edit

## Skill Composition

### Integration Patterns

```typescript
// Pattern 1: Deep-Discuss → TAV
async function clarifyThenExecute(userRequest: string) {
  const discussion = await Skill({ 
    skill: "deep-discuss", 
    args: userRequest 
  })
  
  return tavWorkflow(discussion.conclusion)
}

// Pattern 2: TAV → Review
async function executeAndReview(userRequest: string) {
  await tavWorkflow(userRequest)
  
  return Skill({ skill: "review" })
}

// Pattern 3: Spec-Dev → TAV (per module)
async function specDrivenTav(projectGoal: string) {
  const tasks = await Skill({ skill: "spec-dev", args: projectGoal })
  
  for (const module of tasks.modules) {
    await tavWorkflow({
      scope: module.name,
      requirement: module.description,
      todoList: module.tasks
    })
  }
}

// Pattern 4: TAV → Smart-Commit
async function executeAndCommit(userRequest: string) {
  await tavWorkflow(userRequest)
  
  return Skill({ skill: "smart-commit" })
}
```

## Troubleshooting

### Common Issues

**Issue**: Thinker can't find relevant files
- **Solution**: Use broader Grep patterns, check file naming conventions
- **Fallback**: Ask user for file locations

**Issue**: Actor encounters unexpected code structure
- **Solution**: Stop and return to Thinker for re-analysis
- **Don't**: Try to improvise — incomplete todo-list is a Thinker problem

**Issue**: Verifier finds breaking changes
- **Solution**: Return to Actor with specific fix instructions
- **Escalation**: If fixes fail 3 times, return to Thinker for new approach

**Issue**: Token budget exceeded
- **Solution**: Save state and pause, report to user
- **Resume**: Load state in next conversation and continue

**Issue**: Quality gates fail
- **Solution**: Return to Actor with error output
- **Don't**: Refactor — just fix the specific errors

## Testing the Workflow

### Unit Test Each Phase

```typescript
describe('TAV Workflow', () => {
  describe('Thinker Phase', () => {
    it('should analyze requirements and create todo-list', async () => {
      const output = await runThinkerPhase('Add rate limiting')
      expect(output.todoList).toHaveLength(5)
      expect(output.todoList[0]).toHaveProperty('file')
      expect(output.todoList[0]).toHaveProperty('line')
      expect(output.todoList[0]).toHaveProperty('action')
    })
  })
  
  describe('Actor Phase', () => {
    it('should execute todo-list items', async () => {
      const output = await runActorPhase(mockTodoList)
      expect(output.completedItems).toEqual([1, 2, 3])
      expect(output.changes).toHaveLength(3)
    })
  })
  
  describe('Verifier Phase', () => {
    it('should verify changes and run tests', async () => {
      const output = await runVerifierPhase(mockThinkerOutput, mockActorOutput)
      expect(output.result).toBe('pass')
      expect(output.qualityGates.tests).toBe('pass')
    })
  })
})
```

### Integration Test Full Workflow

```typescript
describe('TAV Workflow Integration', () => {
  it('should complete full workflow for simple change', async () => {
    const result = await tavWorkflow('Add validation to user input')
    
    expect(result.status).toBe('complete')
    expect(result.iterations).toBe(1)
    expect(result.phases.Thinker.status).toBe('completed')
    expect(result.phases.Actor.status).toBe('completed')
    expect(result.phases.Verifier.status).toBe('completed')
  })
  
  it('should handle Actor-Verifier iteration', async () => {
    const result = await tavWorkflow('Fix complex bug')
    
    expect(result.status).toBe('complete')
    expect(result.iterations).toBeGreaterThan(1)
    expect(result.retryCount.actorVerifierLoops).toBeGreaterThan(0)
  })
})
```

---

**End of Implementation Guide**
