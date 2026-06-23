# Example: Refactoring with TAV Workflow

This example demonstrates using TAV workflow to refactor a large function into smaller, testable units.

## User Request

"Refactor the `processOrder` function — it's 200 lines and does too many things"

## Phase 1: Thinker — Analysis

### Thinker Output

```markdown
**[Thinker - Analysis]**
Phase 1 → Analyzing

### Evidence Gathered
- Read file: `src/services/orderService.ts:45-245` — Found processOrder function (201 lines)
  ```typescript
  async function processOrder(orderId: string) {
    // Lines 45-70: Validate order
    // Lines 71-95: Check inventory
    // Lines 96-120: Calculate pricing
    // Lines 121-145: Process payment
    // Lines 146-170: Update inventory
    // Lines 171-195: Send notifications
    // Lines 196-220: Create audit log
    // Lines 221-245: Return result
  }
  ```
- Read file: `tests/services/orderService.test.ts:89-234` — Single large test for processOrder
- Search references: `processOrder` called in 5 places:
  - `src/api/orders.ts:67` — POST /orders endpoint
  - `src/api/orders.ts:123` — PUT /orders/:id endpoint
  - `src/workers/orderQueue.ts:45` — Background job
  - `src/cron/retryOrders.ts:78` — Retry failed orders
  - `tests/services/orderService.test.ts:89` — Test file
- Read file: `src/services/orderService.ts:1-44` — No other functions, all logic in processOrder

### Analysis Conclusion
The function has 7 distinct responsibilities that should be separate functions:
1. Order validation
2. Inventory checking
3. Price calculation
4. Payment processing
5. Inventory updates
6. Notification sending
7. Audit logging

Each responsibility is 20-30 lines and can be extracted into its own function. The main `processOrder` becomes an orchestrator that calls these functions in sequence.

### Todo-list
1. `src/services/orderService.ts:45` — Extract validateOrder function (lines 45-70)
2. `src/services/orderService.ts:71` — Extract checkInventory function (lines 71-95)
3. `src/services/orderService.ts:96` — Extract calculatePricing function (lines 96-120)
4. `src/services/orderService.ts:121` — Extract processPayment function (lines 121-145)
5. `src/services/orderService.ts:146` — Extract updateInventory function (lines 146-170)
6. `src/services/orderService.ts:171` — Extract sendNotifications function (lines 171-195)
7. `src/services/orderService.ts:196` — Extract createAuditLog function (lines 196-220)
8. `src/services/orderService.ts:45-245` — Rewrite processOrder to orchestrate extracted functions
9. `tests/services/orderService.test.ts` — Add unit tests for each extracted function

### Risk Notes
- Must maintain exact same behavior (no logic changes)
- Error handling must be preserved
- Transaction boundaries must be maintained
- All 5 call sites must continue working
- Large refactor — high risk of introducing bugs
```

### State Created

`.tav/state.json`:
```json
{
  "version": "3.0.0",
  "taskId": "tav-20260519-090000",
  "userRequest": "Refactor the processOrder function — it's 200 lines and does too many things",
  "currentPhase": "Actor",
  "phases": {
    "Thinker": {
      "status": "completed",
      "output": {
        "todoList": [
          { "id": 1, "action": "Extract validateOrder", "risk": "medium" },
          { "id": 2, "action": "Extract checkInventory", "risk": "medium" },
          { "id": 3, "action": "Extract calculatePricing", "risk": "medium" },
          { "id": 4, "action": "Extract processPayment", "risk": "high" },
          { "id": 5, "action": "Extract updateInventory", "risk": "high" },
          { "id": 6, "action": "Extract sendNotifications", "risk": "low" },
          { "id": 7, "action": "Extract createAuditLog", "risk": "low" },
          { "id": 8, "action": "Rewrite processOrder orchestrator", "risk": "high" },
          { "id": 9, "action": "Add unit tests", "risk": "medium" }
        ]
      }
    }
  }
}
```

---

## Phase 2: Actor — Execution

### Actor Output

```markdown
**[Actor - Execution]**
Phase 2 → Executing

### Progress
1. ✓ Extract validateOrder
2. ✓ Extract checkInventory
3. ✓ Extract calculatePricing
4. ✓ Extract processPayment
5. ✓ Extract updateInventory
6. ✓ Extract sendNotifications
7. ✓ Extract createAuditLog
8. ✓ Rewrite processOrder orchestrator
9. ✓ Add unit tests

### Details

**Edit 1-7: Extract functions**

```typescript
// NEW: Extracted functions (added before processOrder)

async function validateOrder(orderId: string): Promise<Order> {
  const order = await Order.findById(orderId)
  if (!order) {
    throw new Error('Order not found')
  }
  if (order.status !== 'pending') {
    throw new Error('Order already processed')
  }
  return order
}

async function checkInventory(order: Order): Promise<void> {
  for (const item of order.items) {
    const product = await Product.findById(item.productId)
    if (product.stock < item.quantity) {
      throw new Error(`Insufficient stock for ${product.name}`)
    }
  }
}

async function calculatePricing(order: Order): Promise<PricingResult> {
  let subtotal = 0
  for (const item of order.items) {
    const product = await Product.findById(item.productId)
    subtotal += product.price * item.quantity
  }
  
  const tax = subtotal * 0.1
  const shipping = order.shippingMethod === 'express' ? 15 : 5
  const total = subtotal + tax + shipping
  
  return { subtotal, tax, shipping, total }
}

async function processPayment(order: Order, amount: number): Promise<string> {
  const payment = await stripe.charges.create({
    amount: amount * 100,
    currency: 'usd',
    customer: order.customerId,
    description: `Order ${order.id}`
  })
  return payment.id
}

async function updateInventory(order: Order): Promise<void> {
  for (const item of order.items) {
    await Product.findByIdAndUpdate(item.productId, {
      $inc: { stock: -item.quantity }
    })
  }
}

async function sendNotifications(order: Order): Promise<void> {
  await emailService.send({
    to: order.customerEmail,
    subject: 'Order Confirmed',
    template: 'order-confirmation',
    data: { order }
  })
  
  await smsService.send({
    to: order.customerPhone,
    message: `Your order ${order.id} has been confirmed`
  })
}

async function createAuditLog(order: Order, paymentId: string): Promise<void> {
  await AuditLog.create({
    type: 'order_processed',
    orderId: order.id,
    paymentId,
    timestamp: new Date(),
    metadata: {
      items: order.items.length,
      total: order.total
    }
  })
}
```

**Edit 8: Rewrite processOrder**

```typescript
// BEFORE: 201 lines of inline logic

// AFTER: 25 lines orchestrating extracted functions
async function processOrder(orderId: string) {
  try {
    // Validate
    const order = await validateOrder(orderId)
    
    // Check inventory
    await checkInventory(order)
    
    // Calculate pricing
    const pricing = await calculatePricing(order)
    order.pricing = pricing
    
    // Process payment
    const paymentId = await processPayment(order, pricing.total)
    
    // Update inventory
    await updateInventory(order)
    
    // Update order status
    order.status = 'confirmed'
    order.paymentId = paymentId
    await order.save()
    
    // Send notifications
    await sendNotifications(order)
    
    // Create audit log
    await createAuditLog(order, paymentId)
    
    return { success: true, order }
  } catch (error) {
    await handleOrderError(orderId, error)
    throw error
  }
}
```

**Edit 9: Add unit tests**

```typescript
// NEW: Unit tests for each function

describe('validateOrder', () => {
  it('should return order if valid', async () => {
    const order = await validateOrder('valid-id')
    expect(order).toBeDefined()
    expect(order.status).toBe('pending')
  })
  
  it('should throw if order not found', async () => {
    await expect(validateOrder('invalid-id')).rejects.toThrow('Order not found')
  })
  
  it('should throw if order already processed', async () => {
    await expect(validateOrder('processed-id')).rejects.toThrow('Order already processed')
  })
})

describe('checkInventory', () => {
  it('should pass if stock available', async () => {
    await expect(checkInventory(mockOrder)).resolves.not.toThrow()
  })
  
  it('should throw if insufficient stock', async () => {
    await expect(checkInventory(mockOrderOutOfStock)).rejects.toThrow('Insufficient stock')
  })
})

describe('calculatePricing', () => {
  it('should calculate correct totals', async () => {
    const pricing = await calculatePricing(mockOrder)
    expect(pricing.subtotal).toBe(100)
    expect(pricing.tax).toBe(10)
    expect(pricing.shipping).toBe(5)
    expect(pricing.total).toBe(115)
  })
  
  it('should apply express shipping cost', async () => {
    const pricing = await calculatePricing(mockOrderExpress)
    expect(pricing.shipping).toBe(15)
  })
})

// ... tests for other functions
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
| Requirement met | ✓ | Function refactored into 7 smaller functions |
| Behavior preserved | ⚠ | Need to verify — see below |
| Syntax correct | ✓ | No syntax errors |
| Type safe | ✓ | TypeScript correct |
| Tests added | ✓ | Unit tests for each function |
| Error handling | ✓ | Preserved in orchestrator |
| Call sites work | ⚠ | Need to verify |

### Detailed Verification

**1. Run existing integration test:**

```bash
$ npm test -- orderService.test.ts

PASS tests/services/orderService.test.ts
  ✓ should process order successfully (145ms)
  ✓ should handle payment failure (89ms)
  ✓ should handle inventory shortage (67ms)
```

**2. Run new unit tests:**

```bash
$ npm test -- orderService.unit.test.ts

PASS tests/services/orderService.unit.test.ts
  validateOrder
    ✓ should return order if valid (12ms)
    ✓ should throw if order not found (8ms)
    ✓ should throw if order already processed (9ms)
  checkInventory
    ✓ should pass if stock available (15ms)
    ✓ should throw if insufficient stock (11ms)
  calculatePricing
    ✓ should calculate correct totals (7ms)
    ✓ should apply express shipping cost (6ms)
  ... (14 more tests pass)
```

**3. Check call sites:**

```bash
$ npm run type-check
✓ No type errors

$ grep -r "processOrder" src/
src/api/orders.ts:67:    const result = await processOrder(orderId)
src/api/orders.ts:123:   const result = await processOrder(orderId)
src/workers/orderQueue.ts:45:  await processOrder(job.data.orderId)
src/cron/retryOrders.ts:78:    await processOrder(order.id)
```

All call sites still work (same function signature).

**4. Code quality check:**

```bash
$ npm run lint
✓ All files pass

$ npm run complexity
orderService.ts:
  processOrder: complexity 3 (was 45) ✓
  validateOrder: complexity 2 ✓
  checkInventory: complexity 3 ✓
  ... (all functions < 5 complexity)
```

### Issue Found

**Minor Issue:**
- `processPayment` function doesn't handle Stripe errors gracefully
- If payment fails, inventory is not checked, but error handling could be clearer

**Current code:**
```typescript
async function processPayment(order: Order, amount: number): Promise<string> {
  const payment = await stripe.charges.create({ ... })
  return payment.id
}
```

**Suggested Enhancement:**
```typescript
async function processPayment(order: Order, amount: number): Promise<string> {
  try {
    const payment = await stripe.charges.create({ ... })
    return payment.id
  } catch (error) {
    throw new Error(`Payment failed: ${error.message}`)
  }
}
```

### Review Result

**Status: PASS with minor suggestion**

All critical checks passed:
- ✓ Behavior preserved (integration tests pass)
- ✓ Each function is testable (unit tests added)
- ✓ Complexity reduced (45 → 3)
- ✓ Call sites unaffected
- ✓ Error handling preserved

The payment error handling suggestion is optional — current code works, but explicit error wrapping would be clearer.

### Change Summary
- Files modified: 2 (orderService.ts, tests)
- Lines before: 245
- Lines after: 280 (more lines, but much more maintainable)
- Functions: 1 → 8
- Complexity: 45 → 3 (per function)
- Test coverage: 1 integration test → 1 integration + 21 unit tests

### Metrics
- Cyclomatic complexity: 45 → 3 (93% reduction)
- Function length: 201 lines → 25 lines (88% reduction)
- Testability: Low → High (each function independently testable)
- Maintainability: Low → High (single responsibility per function)

✓ Task complete
```

---

## Phase 4: Complete

```markdown
**[TAV Workflow - Complete]**

### Summary
✓ Successfully refactored 201-line function into 8 focused functions

### Before
```typescript
async function processOrder(orderId: string) {
  // 201 lines of mixed responsibilities
  // Complexity: 45
  // Testability: Low (one giant integration test)
}
```

### After
```typescript
// 7 focused functions (20-30 lines each)
async function validateOrder(orderId: string): Promise<Order>
async function checkInventory(order: Order): Promise<void>
async function calculatePricing(order: Order): Promise<PricingResult>
async function processPayment(order: Order, amount: number): Promise<string>
async function updateInventory(order: Order): Promise<void>
async function sendNotifications(order: Order): Promise<void>
async function createAuditLog(order: Order, paymentId: string): Promise<void>

// 1 orchestrator (25 lines)
async function processOrder(orderId: string) {
  // Calls extracted functions in sequence
  // Complexity: 3
  // Testability: High (each function independently testable)
}
```

### Improvements
- **Complexity:** 45 → 3 (93% reduction)
- **Function length:** 201 → 25 lines (88% reduction)
- **Test coverage:** 1 integration test → 22 tests (1 integration + 21 unit)
- **Maintainability:** Each function has single responsibility
- **Debuggability:** Easier to isolate issues
- **Reusability:** Functions can be used independently

### Changes
1. src/services/orderService.ts — Extracted 7 functions, rewrote orchestrator
2. tests/services/orderService.unit.test.ts — Added 21 unit tests

### Metrics
- Files modified: 2
- Lines changed: +280 -201 (net: +79 lines)
- Functions: 1 → 8
- Test coverage: 45% → 92%
- Token usage: 15,234
- Duration: 35 minutes

### Quality Gates
✓ Lint: Pass
✓ Type check: Pass
✓ Tests: Pass (22/22)
✓ Complexity: Pass (all functions < 5)
✓ Integration tests: Pass (behavior preserved)

✓ Task complete
```

---

## Key Takeaways

### Why This Refactoring Succeeded

1. **Thinker identified clear boundaries:**
   - 7 distinct responsibilities
   - Each 20-30 lines
   - Natural extraction points

2. **Actor maintained behavior:**
   - No logic changes
   - Exact same error handling
   - Same function signature (call sites unaffected)

3. **Verifier confirmed correctness:**
   - Integration tests still pass (behavior preserved)
   - Unit tests added (each function testable)
   - Complexity metrics improved

### Benefits of Extracted Functions

**Before (Monolithic):**
```typescript
async function processOrder(orderId: string) {
  // 201 lines doing everything
  // Hard to test specific logic
  // Hard to understand
  // Hard to modify
}
```

**After (Modular):**
```typescript
// Each function is:
// - Small (20-30 lines)
// - Focused (single responsibility)
// - Testable (unit tests)
// - Reusable (can be called independently)
// - Understandable (clear purpose)

async function validateOrder(orderId: string): Promise<Order>
async function checkInventory(order: Order): Promise<void>
async function calculatePricing(order: Order): Promise<PricingResult>
// ... etc
```

### Testing Strategy

**Integration Test (Preserved):**
```typescript
// Tests the full flow end-to-end
it('should process order successfully', async () => {
  const result = await processOrder('order-123')
  expect(result.success).toBe(true)
  // Verifies entire workflow
})
```

**Unit Tests (New):**
```typescript
// Tests each function in isolation
it('should calculate correct pricing', async () => {
  const pricing = await calculatePricing(mockOrder)
  expect(pricing.total).toBe(115)
  // Fast, focused, no dependencies
})
```

### Complexity Reduction

**Before:**
- Cyclomatic complexity: 45
- Cognitive load: Very high
- Debugging: Hard (which of 201 lines?)

**After:**
- Cyclomatic complexity: 3 per function
- Cognitive load: Low (each function simple)
- Debugging: Easy (isolate to specific function)

### Real-World Impact

**Scenario: Bug in pricing calculation**

**Before:**
- Read 201 lines to find pricing logic
- Modify lines 96-120
- Run full integration test (slow)
- Hope nothing else broke

**After:**
- Read `calculatePricing` function (25 lines)
- Modify function
- Run unit test for `calculatePricing` (fast)
- Integration test confirms no side effects

**Time saved:** 80% faster to debug and fix

---

## Alternative Scenarios

### Scenario 1: Verifier Finds Behavior Change

If integration tests failed:

```markdown
### Issue Details
- Integration test "should process order successfully" fails
- Expected: order.status = 'confirmed'
- Actual: order.status = 'pending'

### Root Cause
- Line 18 in new processOrder: missing `await order.save()`

### Suggested Fix
Return to Actor:
- `src/services/orderService.ts:18` — Add `await` before `order.save()`

→ Return to Phase 2: Fix missing await
```

### Scenario 2: Actor Finds Unclear Boundaries

If Actor couldn't determine extraction points:

```markdown
**[Actor - Execution]**
Phase 2 → Interrupted

### Issue Found
While executing Todo item 3:
- Lines 96-120 (pricing calculation) are tightly coupled with lines 121-145 (payment)
- Can't extract cleanly without changing logic
- Need Thinker to re-analyze boundaries

→ Return to Phase 1: Re-analyze extraction strategy
```

### Scenario 3: Too Many Extractions

If Thinker over-extracted:

```markdown
### Verifier Feedback
- 15 functions extracted (too granular)
- Some functions are only 3-5 lines
- Over-abstraction makes code harder to follow

### Suggested Adjustment
- Merge related functions
- Keep functions that are 20+ lines
- Inline functions < 10 lines

→ Return to Phase 1: Adjust extraction granularity
```

---

**End of Example**
