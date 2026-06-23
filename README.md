# TAV Workflow - README

## Overview

TAV (Think-Act-Verify) is a structured three-role collaboration workflow for code modifications, feature development, and bug fixes. It ensures every change has independent perspectives for analysis, execution, and verification.

Agent and task-tool names in this package are role aliases. Map them to the current platform's available planning, execution, verification, and todo tools.

**Version**: 3.0.0  
**Status**: Stable

## Quick Start

### Basic Usage

```typescript
// User request
"Add rate limiting to the login API"

// TAV workflow automatically:
// 1. Thinker analyzes the requirement
// 2. Actor executes the changes
// 3. Verifier reviews and validates
// 4. Returns complete or iterates if needed
```

### When to Use

✅ **Use TAV for:**
- Code modifications (bug fixes, feature adjustments)
- New feature development
- Local refactoring
- Configuration changes

❌ **Don't use TAV for:**
- Pure information queries
- Simple file reads
- Single-file operations with clear instructions
- Full-project rewrites, migrations, rebuilds, or architecture overhauls; use `spec-driven-develop` first

## Key Features

### 🤖 Automated Agent Orchestration
- Thinker, Actor, and Verifier roles execute automatically
- No manual interpretation needed
- Structured prompts ensure consistency

### 💾 State Persistence
- Cross-conversation continuity via `.tav/state.json`
- Resume interrupted workflows
- State archiving on completion

### 📊 Native Tool Integration
- TodoWrite for task tracking
- Optional platform-specific workflow progress tool, if available
- Real-time visibility in IDE

### ✅ Quality Gates
- Automated lint, type-check, test execution
- Runs after Actor phase
- Catches errors before Verifier

### 🔄 Error Recovery
- Structured retry logic
- Automatic escalation
- No infinite loops

### ⚡ Performance Optimized
- Token budget tracking per phase
- Efficiency rules for each role
- 35% token reduction vs manual execution

## Architecture

```
User Request
    ↓
Continuity Check (.tav/state.json exists?)
    ↓
Phase 1: Thinker (Analysis)
    - Read code files
    - Create todo-list
    - Document risks
    ↓
Phase 2: Actor (Execution)
    - Execute todo items
    - Minimal changes only
    - Match existing style
    ↓
Quality Gates (Automated)
    - Lint check
    - Type check
    - Tests
    ↓
Phase 3: Verifier (Review)
    - Independent verification
    - Run tests
    - Check side effects
    ↓
Complete or Iterate
```

## Examples

### Example 1: Add API Rate Limiting

See [examples/rate-limiting.md](examples/rate-limiting.md) for complete walkthrough.

**Summary:**
- Thinker: Analyzed login endpoint, found Redis available
- Actor: Added express-rate-limit with Redis store
- Verifier: Confirmed tests pass, no side effects
- Result: 5 attempts/15min rate limit implemented
- Metrics: 1 iteration, 10,789 tokens, 20 minutes

### Example 2: Fix Bug with Iteration

See [examples/bug-fix.md](examples/bug-fix.md) for complete walkthrough.

**Summary:**
- Thinker: Found missing `await` on `user.save()`
- Actor: Added `await`
- Verifier: Tests failed - deeper issue found
- Actor (iteration 2): Fixed Mongoose change detection
- Verifier: Tests pass
- Result: Bug fixed correctly after 2 iterations
- Metrics: 2 iterations, 12,456 tokens, 25 minutes

### Example 3: Refactor Large Function

See [examples/refactoring.md](examples/refactoring.md) for complete walkthrough.

**Summary:**
- Thinker: Identified 7 distinct responsibilities in 201-line function
- Actor: Extracted 7 functions, rewrote orchestrator
- Verifier: Confirmed behavior preserved, tests pass
- Result: Complexity 45 → 3, 22 tests added
- Metrics: 1 iteration, 15,234 tokens, 35 minutes

## Configuration

### Token Budgets

| Phase | Target | Max |
|-------|--------|-----|
| Thinker | 5,000 | 10,000 |
| Actor | 3,000 | 8,000 |
| Verifier | 2,000 | 5,000 |

### Retry Limits

| Scenario | Max Attempts |
|----------|--------------|
| Thinker clarification | 3 rounds |
| Actor-Verifier loop | 3 iterations |
| Thinker re-analysis | 2 rounds |
| Total workflow iterations | 5 |

### State File

Location: `.tav/state.json`

Add to `.gitignore`:
```
.tav/
```

## Integration with Other Skills

### Pattern 1: Deep-Discuss → TAV
```typescript
// Clarify requirements first
Skill({ skill: "deep-discuss", args: userRequest })
// Then execute with TAV
tavWorkflow(clarifiedRequirement)
```

### Pattern 2: TAV → Review
```typescript
// Execute changes
tavWorkflow(userRequest)
// Then PR-level review
Skill({ skill: "review" })
```

### Pattern 3: Spec-Dev → TAV
```typescript
// Generate module tasks
Skill({ skill: "spec-dev" })
// Apply TAV to each module
for (const module of modules) {
  tavWorkflow(module.tasks)
}
```

### Pattern 4: TAV → Smart-Commit
```typescript
// Execute changes
tavWorkflow(userRequest)
// Create commit with quality gates
Skill({ skill: "smart-commit" })
```

## Performance

### Token Efficiency

**Average token usage per workflow:**
- Simple change: ~8,000 tokens
- Bug fix: ~12,000 tokens
- Refactoring: ~15,000 tokens

**Efficiency improvements:**
- 35% reduction vs manual execution
- Parallel reads in Thinker phase
- No re-reads in Actor phase
- Targeted verification in Verifier phase

### Execution Speed

**Average duration:**
- Simple change: 15-20 minutes
- Bug fix: 20-30 minutes
- Refactoring: 30-45 minutes

**Speed improvements:**
- Parallel file reads
- Batch edits
- Single test run

## Troubleshooting

### Common Issues

**Issue**: Thinker can't find relevant files
- **Solution**: Use broader Grep patterns
- **Fallback**: Ask user for file locations

**Issue**: Actor encounters unexpected code structure
- **Solution**: Stops and returns to Thinker
- **Don't**: Try to improvise

**Issue**: Verifier finds breaking changes
- **Solution**: Returns to Actor with fix instructions
- **Escalation**: After 3 attempts, returns to Thinker

**Issue**: Token budget exceeded
- **Solution**: Saves state and pauses
- **Resume**: Load state in next conversation

**Issue**: Quality gates fail
- **Solution**: Returns to Actor with error output
- **Don't**: Refactor - just fix errors

## Documentation

### Core Documentation
- [SKILL.md](SKILL.md) - Complete skill specification
- [CHANGELOG.md](CHANGELOG.md) - Version history

### Implementation
- [Implementation Guide](references/implementation-guide.md) - Technical implementation details

### Templates
- [State Template](references/templates/state.json) - State file schema
- [Thinker Output](references/templates/thinker-output.md) - Thinker output format
- [Actor Output](references/templates/actor-output.md) - Actor output format
- [Verifier Output](references/templates/verifier-output.md) - Verifier output format

### Examples
- [Rate Limiting](examples/rate-limiting.md) - API rate limiting implementation
- [Bug Fix](examples/bug-fix.md) - Bug fix with iteration
- [Refactoring](examples/refactoring.md) - Large function refactoring

## Version History

### v3.0.0 (2026-05-19) - Current
- ✨ Automated agent orchestration
- 💾 State persistence
- 📊 Native tool integration
- ✅ Quality gates
- 🔄 Error recovery
- ⚡ Performance optimization
- 📚 Complete examples

### v2.0.0 (Previous)
- Initial three-role workflow definition
- Manual execution model

## Contributing

### Reporting Issues
- File issues in project repository
- Include state file (`.tav/state.json`) if applicable
- Describe expected vs actual behavior

### Suggesting Enhancements
- Describe use case
- Explain why current workflow doesn't handle it
- Propose solution

## License

MIT

## Acknowledgments

Inspired by:
- `spec-driven-develop` skill - State persistence patterns
- `pro-workflow` skill - Quality gate patterns
- User feedback - Need for automation

---

**TAV Workflow v3.0.0**  
*Think-Act-Verify: Structured collaboration for better code*
# tav-workflow
