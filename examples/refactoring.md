# Example: Behavior-Preserving Refactor

Demonstrates TAV on a local refactor where the hard requirement is that behavior must not change, plus the recovery paths when the plan does not survive contact with the code.

## User Request

"Refactor the `processOrder` function - it's 200 lines and does too many things"

## Phase 1: Thinker - Analysis

```markdown
**[Thinker - Analysis]**
Phase 1 -> Analyzing

### Task Classification
- Tier: L1
- Risk level: high (payment and inventory logic; 5 call sites)
- Escalation: use `spec-driven-develop` first? no (single module, known target)

### Evidence Gathered
- `src/services/orderService.ts:45-245` - processOrder, 201 lines, 7 sequential responsibilities: validate order, check inventory, calculate pricing, process payment, update inventory, send notifications, write audit log.
- Search `processOrder` - 5 call sites: `src/api/orders.ts:67`, `src/api/orders.ts:123`, `src/workers/orderQueue.ts:45`, `src/cron/retryOrders.ts:78`, and the test file.
- `tests/services/orderService.test.ts:89-234` - integration tests cover success, payment failure, and inventory shortage; they are the behavior baseline.

### Analysis Summary
- Extract each responsibility into a private function of 20-30 lines; `processOrder` becomes a 25-line orchestrator with the same signature, so no call site changes. Integration tests must pass unchanged to prove behavior is preserved.

### Todo List
1. `src/services/orderService.ts` - extract `validateOrder` (lines 45-70).
2. `src/services/orderService.ts` - extract `checkInventory` (71-95).
3. `src/services/orderService.ts` - extract `calculatePricing` (96-120).
4. `src/services/orderService.ts` - extract `processPayment` (121-145).
5. `src/services/orderService.ts` - extract `updateInventory` (146-170).
6. `src/services/orderService.ts` - extract `sendNotifications` (171-195).
7. `src/services/orderService.ts` - extract `createAuditLog` (196-220).
8. `src/services/orderService.ts` - rewrite `processOrder` as orchestrator; keep signature and error handling identical.
9. `tests/services/orderService.unit.test.ts` - add unit tests per extracted function.

### Risks
- Any logic drift during extraction changes order processing behavior.
- Transaction/error-handling boundaries must stay exactly where they are.
- Existing integration tests are the contract; they must pass without modification.

### Verification Plan
- `npm test -- orderService` - integration (unchanged) + new unit tests.
- `npm run typecheck`, `npm run lint`.
```

## Phase 2: Actor - Execution

```markdown
**[Actor - Execution]**
Phase 2 -> Executing

### Progress
1. Completed todo 1-7 - seven functions extracted, logic moved verbatim.
2. Completed todo 8 - processOrder rewritten as orchestrator, same signature.
3. Completed todo 9 - 21 unit tests added.

### Blocked Items
- None.

### Next Phase
- Enter Verifier.
```

The orchestrator after extraction:

```typescript
async function processOrder(orderId: string) {
  try {
    const order = await validateOrder(orderId)
    await checkInventory(order)
    const pricing = await calculatePricing(order)
    order.pricing = pricing
    const paymentId = await processPayment(order, pricing.total)
    await updateInventory(order)
    order.status = 'confirmed'
    order.paymentId = paymentId
    await order.save()
    await sendNotifications(order)
    await createAuditLog(order, paymentId)
    return { success: true, order }
  } catch (error) {
    await handleOrderError(orderId, error)
    throw error
  }
}
```

## Phase 3: Verifier - Review

```markdown
**[Verifier - Review]**
Phase 3 -> Reviewing

### Diff Reviewed
- `git diff` shows changes confined to `orderService.ts` and the new unit test file; extracted bodies match the original line ranges; error handling and `order.save()` placement unchanged.

### Verification Items

| Check | Status | Evidence |
|-------|--------|----------|
| Requirement met | pass | 1 function -> 8 focused functions |
| Syntax/type safety | pass | `npm run typecheck` clean |
| Tests/lint | pass | integration 3/3 unchanged and green; unit 21/21 |
| Compatibility | pass | signature identical; grep confirms all 4 production call sites compile untouched |
| Edge cases | pass | payment-failure and inventory-shortage integration tests still pass |
| Security | pass | no auth/input surface changed |
| Side effects | warn | `processPayment` propagates raw Stripe errors; wrapping would be clearer (optional) |

### Commands Run
- `npm test -- orderService` - passed (24 tests).
- `npm run typecheck` - passed.
- `npm run lint` - passed.

### Issue Details
- None blocking.

### Suggested Fix
- Optional: wrap Stripe errors in `processPayment` for clearer messages. Not part of the approved plan; record as follow-up, do not improvise.

### Consolidation Candidates
- None. Extraction boundaries and the behavior-contract rule are visible in the code and tests; nothing here outlives the task (zero captures is the default outcome).

### Review Result
- Pass and enter Phase 4.

### Change Summary
- Files modified: 1, files created: 1 (from `git diff --stat`)
- Lines changed: +280 -201 (from `git diff --stat`)
- Scope: extraction refactor, behavior preserved
```

## Phase 4: Completion

```markdown
## 变更摘要
- 将 201 行的 processOrder 拆分为 7 个单一职责函数加 1 个 25 行编排器，签名不变，行为由原有集成测试保证不变。

## 涉及文件
- `src/services/orderService.ts` (Modified): 提取 7 个函数并重写编排器。
- `tests/services/orderService.unit.test.ts` (Added): 21 个单元测试。

## 验证结果
- ✅ `npm test -- orderService` passed (24 passing, 集成测试未修改)
- ✅ `npm run typecheck` passed
- ✅ `npm run lint` passed

## 失败或未执行的命令
- None.

## 剩余风险
- processPayment 直接透传 Stripe 原始错误，信息可读性一般。

## 后续建议
- 如需更清晰的支付错误信息，单独立项包装 Stripe 异常。
```

## Recovery Scenarios

**Integration test fails after extraction** - e.g. `order.status` stays `pending` because an `await order.save()` was dropped during extraction. Verifier returns to Actor with the exact line; behavior contract violated means the refactor is wrong, not the test.

**Actor cannot extract cleanly** - pricing and payment logic turn out to be interleaved (shared mutable locals). Structural mismatch with the plan: stop, return to Thinker to re-draw extraction boundaries instead of forcing a lossy split.

**Over-extraction flagged by Verifier** - 15 fragments of 3-5 lines each would hurt readability. Verifier returns to Thinker to merge related steps; extraction granularity is a design decision, not an Actor improvisation.

## Key Takeaways

1. **Unchanged integration tests are the behavior contract.** They must pass without edits; unit tests are additive.
2. **Same signature means zero call-site risk.** The orchestrator pattern keeps all 4 production call sites untouched.
3. **Optional improvements are follow-ups, not improvisations.** The Stripe error wrapping stays out of scope because it was not in the approved plan.

---

**End of Example**
