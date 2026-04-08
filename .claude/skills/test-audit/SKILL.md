---
name: test-audit
description: Post-test audit skill — launches 3-5 domain-expert review agents to find tautological tests, false confidence, missing edge cases, and upstream bugs before committing
user_invocable: true
---

# /test-audit — Post-Test Audit

Invoke after writing tests, before committing. Launches parallel expert review agents that ruthlessly audit test quality.

## When to invoke
- After writing >3 new tests
- Before committing any test file
- After significant refactoring of existing tests
- When unsure if tests are actually catching real bugs

## Process

### Step 1: Identify the code under test
Read the test file(s). Determine:
- What production code is being tested
- What domain the code belongs to (payment parsing, crypto, UI, storage, etc.)

### Step 2: Select 3-5 expert reviewers
Based on the domain, pick from the roster below. Always include at least one from each category:

**Always include:**
- A domain expert for the specific code (Bitcoin, Lightning, Liquid, Flutter, etc.)
- A testing methodology expert (catches tautological tests, false confidence)

**Add based on domain:**
- Financial code → financial math specialist + security specialist
- Parsing/routing code → protocol expert for each format (BIP21, BOLT11, etc.)
- Crypto code → cryptographer + BIP spec expert
- UI code → Flutter architect + UX specialist
- Storage code → database specialist + migration expert

### Step 3: Launch agents in parallel
Each agent receives:
1. The test file(s) to review
2. The production code being tested
3. The audit checklist (below)
4. Instructions to be harsh — this code handles real money

### Step 4: Synthesize findings
After all agents report:
1. Deduplicate findings across reviewers
2. Classify: CRITICAL / MEDIUM / LOW / OK
3. Separate into:
   - **Test quality issues** (our tests are weak) → fix before committing
   - **Upstream bugs found** (production code has issues) → verify before reporting
   - **Design questions** (unclear if bug or intentional) → verify before flagging

### Step 5: Verify each upstream finding (MANDATORY — prevents false bug reports)
For every suspected production bug, launch a verification agent that:

1. **Prove reachability** — Trace ALL callers of the suspect function. No caller = dead code, not a bug.
2. **Check defenses** — Do callers validate inputs before reaching the suspect code? Does a type system or contract prevent the bad state?
3. **Trace causality backward** (NASA fault tree) — Start from the user-visible symptom, work backward. Prune branches defended by existing checks.
4. **Assess impact** — Even if reachable, what's the worst outcome? Silent data corruption > crash > cosmetic.
5. **Classify** with one of:
   - **CONFIRMED REACHABLE** — reproducible, reachable in production, violates spec → report to team
   - **LATENT BUG** — real but currently defended/unreachable — document as foot-gun
   - **DEAD CODE** — path exists but no caller reaches it → document only
   - **BY DESIGN** — caller contract guarantees correctness → not a bug
   - **NEEDS TEAM INPUT** — ambiguous, could go either way → ask

Why this step matters: In our first retroactive audit, 4 suspected "CRITICAL production bugs" were flagged. After verification, only 1 was confirmed reachable. Without this step, we'd have filed 3 false bug reports.

### Step 6: Fix, document, and commit
- Fix all CRITICAL test quality issues before committing
- For every finding NOT fixed, add an entry to `project_known_test_gaps.md` (memory) with:
  - **What**: the gap
  - **Why not fixed**: specific reason (dead code, by-design, can't compute expected value, theoretical)
  - **Revisit when**: a trigger condition that would make this worth fixing
- Update `project_upstream_findings.md` with verified classifications for any upstream bugs
- Never assert upstream behavior as "correct" if it might be a bug — use "documents current behavior" language
- Every item from the audit must end up in one of three places:
  1. **Fixed** → in the code
  2. **Upstream bug** → in `project_upstream_findings.md`
  3. **Known gap** → in `project_known_test_gaps.md`
  Nothing should be silently dropped.

## Audit Checklist (given to each reviewer agent)

Each reviewer must check every test against these criteria:

### 1. Tautology Check
Does any assertion test something that cannot fail?
- `expect('bc1'.startsWith('bc1'), isTrue)` → tautological
- `expect(positiveNumber, greaterThan(0))` on a literal → tautological
- Asserting an enum's `.name` equals its string → tautological

### 2. Code-Under-Test Check
Trace the call chain from the test assertion back to production code.
- Does it call a function from `lib/`? → OK
- Does it only call library functions (bip21_uri, bolt11_decoder)? → document clearly
- Does it test Dart language features (String.startsWith, List.length)? → delete

### 3. False-Green Check
If the core production logic were deleted/inverted, would this test still pass?
- If yes → the test catches nothing
- The reviewer should mentally simulate this for each test

### 4. Normalization Masking Check
Does the test apply any transformation to the actual value before asserting?
- `.toLowerCase()`, `.trim()`, `.round()`, `.abs()` on actuals → flag
- Each transformation can hide a real bug in the production code

### 5. Financial Completeness Check
For any function handling money/amounts/addresses:
- Zero amount tested?
- Negative amount tested?
- 1 satoshi (minimum unit) tested?
- Maximum supply (21M BTC / 2.1 quadrillion sats) tested?
- Rounding boundaries tested?
- Off-by-one satoshi tested?

### 6. Upstream Behavior Documentation
If the test asserts on behavior of upstream code (lib/ files we don't own):
- Is it documented as "current behavior" not "correct behavior"?
- Is it in `project_upstream_findings.md` if it might be a bug?
- Will the test break if the team fixes the behavior?

### 7. Expected Value Source Check
Where does the expected value in each assertion come from?
- From the spec/standard (BIP21, BOLT11, BIP32) → good
- From manual calculation → acceptable
- Computed by the same logic as production code → tautological, flag it

## Agent Prompt Template

```
You are a [DOMAIN] expert reviewing test code for a Bitcoin wallet app.
This code handles real money. Be harsh.

Review: [TEST_FILE_PATH]
Production code: [PRODUCTION_FILE_PATH]

Run every check in the audit checklist. For each test, report:
- [CRITICAL]: Test gives false confidence or misses fund-affecting bugs
- [MEDIUM]: Coverage gap or quality issue
- [LOW]: Minor improvement
- [OK]: Test is solid

Also report any bugs you find in the PRODUCTION code (not just the tests).
```

## Output format
Summary table of findings by severity, then detailed findings with file:line references and fix suggestions.
