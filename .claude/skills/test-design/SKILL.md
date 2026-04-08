---
name: test-design
description: Pre-test design skill — analyzes production code, identifies testable layers, selects expert perspectives, outputs a test plan where every test must name the bug it catches
user_invocable: true
---

# /test-design — Pre-Test Design

Invoke before writing tests for a new area of code. Produces a test plan where every test names the specific bug it would catch.

## Process

### Step 1: Read the production code
Read the file(s) the user wants to test. Understand:
- What the code does (inputs, outputs, side effects)
- What layers exist (pure Dart vs FFI vs network)
- What data flows through it (especially money amounts, addresses, keys)

### Step 2: Classify testability
For each function/method, classify:
- **Pure Dart** → unit testable with `flutter test`
- **FFI dependency** (bdk_dart, lwk, boltz) → needs emulator or E2E test
- **Network dependency** (HTTP, WebSocket) → needs mocking or integration test
- **State dependency** (Hive, SQLite, SecureStorage) → needs mocking or setup

### Step 3: Identify the threat model
Ask: "What's the worst thing that happens if this code is wrong?"
- **Fund loss**: wrong address, wrong amount, wrong network → DO-178C rigor
- **Fund stuck**: transaction rejected, fee too low → high priority
- **Data corruption**: wrong state, lost data → medium priority
- **UI wrong**: wrong text, wrong screen → standard priority

### Step 4: Select expert perspectives (3-5)
Based on the code domain, select reviewers from this roster:

**Financial/Protocol:**
- Bitcoin protocol engineer (BIP standards, address formats, transaction structure)
- Lightning protocol engineer (BOLT11, LNURL, channel state)
- Liquid/Elements specialist (confidential transactions, federation)
- Cryptographer (key derivation, signing, hashing)
- Financial math specialist (precision, rounding, overflow)

**Software Engineering:**
- Dart/Flutter architect (Freezed, Drift, state management)
- Security/input validation specialist (injection, overflow, edge cases)
- Testing methodology expert (property-based testing, mutation testing)
- Dependency/supply chain auditor (FFI bindings, package versions)

**Domain:**
- UX/accessibility testing expert (screen readers, RTL, edge devices)
- CI/CD infrastructure engineer (emulators, device farms, flakiness)
- Mobile platform specialist (Android/iOS specifics, permissions)

### Step 5: Output the test plan
For each test to write, specify:
```
Test: [name]
Bug it catches: [specific scenario that would cause user harm]
Layer: [pure Dart / FFI / E2E]
Edge cases: [zero, negative, max, empty, null, case sensitivity, etc.]
Expected values from: [spec, manual calculation, known test vector]
```

### Step 6: Call out what CANNOT be tested
Explicitly list functions that need FFI/network and cannot be unit tested. These go on the E2E test backlog.

## Anti-patterns to flag during design
- Tests that would only test library behavior (not app code)
- Tests that would recompute expected values using the same logic as production
- Tests where the assertion could never fail (tautological)
- Missing edge cases for any function touching money
- Testing string operations instead of production functions (the startsWith trap)
- Using .toLowerCase()/.round() on actuals in assertions (normalization masking)

## Reachability pre-check
Before writing tests that assert on upstream behavior:
- Trace callers: is the code path reachable from user actions?
- Check defenses: do callers validate inputs before reaching this code?
- If unreachable: document as dead code, don't write tests that assert its behavior as "correct"
- If ambiguous: flag for verification during /test-audit step

## Output format
Produce a numbered test plan. The user reviews it before implementation begins.
