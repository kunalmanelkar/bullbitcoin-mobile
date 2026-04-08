---
name: engineering-sop
description: Engineering best practices SOP for the Bull Bitcoin E2E test suite — commit workflow, test quality gates, code organization
---

# Engineering SOP — Bull Bitcoin E2E Test Suite

## Sources
- Kent Beck — Canon TDD, Test Desiderata (2024)
- Google Engineering Practices — Small CLs, Testing Blog
- Martin Fowler — Test Architecture, Test Doubles
- Jake Wharton / Square — Robot Pattern, strict green-before-merge
- VGV (Very Good Ventures) — Robot Pattern for Flutter
- DO-178C Level A — Safety-critical coverage (100% MC/DC for fund-routing code)
- Bitcoin Core — ACK/NACK review, differential fuzzing
- Trail of Bits — Mutation testing as meta-test (2025)

## Pre-Session Checklist
1. Check disk: `df -h /` — require >= 30GB free
2. Sync upstream: `git fetch upstream && git rebase upstream/main`
3. Verify emulator: `adb devices` — boot if needed
4. Check working tree: `git status` — commit or stash any uncommitted work

## Development Cycle
```
1. PICK        — highest-value test scenario from plan
2. /test-design — analyze code, identify layers, select experts, output test plan
3. WRITE       — implement tests from the plan
4. RUN         — all green
5. /test-audit  — launch expert reviewers, find issues
6. VERIFY      — for each suspected upstream bug: trace callers, prove reachability, classify
7. COMMIT      — atomic, one logical change, ~100 lines
7. PUSH       — push to fork
8. REPEAT
```

## Test Quality Gates
- `/test-design` before writing tests for a new area of code
- `/test-audit` before committing any test file with >3 new tests
- Every test must name the specific bug it catches
- Fund-routing code requires DO-178C rigor: every boolean condition independently affects outcome
- Upstream bugs go in `project_upstream_findings.md`, not as test assertions

## Commit Standards (Google Small CLs)
- One self-contained change per commit, ~100 lines ideal
- NEVER mix refactoring with feature work
- Descriptive message: what changed AND why
- Include Co-Authored-By for Claude-assisted commits

## Test Writing Standards
- All E2E assertion text from `patrol_test/helpers/test_constants.dart`
- Constants sourced from `localization/app_en.arb`
- Use `waitForText()` polling — NEVER `pumpAndSettle()`
- Use `$.tester.tap()` for bottom/obscured buttons
- Run `patrol develop` for iteration, `patrol test` for verification

## Code Organization
```
patrol_test/
  robots/           — one Robot per screen, extends BaseRobot
  journeys/         — compose robots into user story tests
  helpers/          — test_constants.dart + test_helpers.dart
  app_launch_test.dart — smoke test
test/property/      — property-based tests (kiri_check) + BIP32 vectors + parsing tests
```

## CI Strategy (Firebase Test Lab)
- arm64 APKs crash on x86 GHA emulators — use Firebase Test Lab (~$1/run)
- BrowserStack broken with Patrol 4.x — avoid
- Build APKs on `ubuntu-latest`, upload to FTL via gcloud

## Mainnet Testing (Pioneering)
- Automated Liquid mainnet tests with real L-BTC
- Mnemonic in `.env` (gitignored), GitHub Secrets for CI
- Derivation path `m/84'/0'/100'` for isolation
- Boltz swap minimum: 50,000 sats. Liquid tx fees: ~30-50 sats
- Balance cap: $10-20. CI: `workflow_dispatch` only, never on fork PRs

## Upstream Code Policy
- `patrol_test/`, `test/` = our code, no conflict risk
- `lib/` = upstream, do NOT modify except surgical ValueKey additions
- Upstream bugs documented in `project_upstream_findings.md` with classification

## Fork Workflow
- `origin` = our fork (push here)
- `upstream` = SatoshiPortal (pull from here)
- **NEVER commit to fork's `main`**
- All work on feature branches (currently `e2e-test-suite`)
- Sync before major work: `git fetch upstream && git rebase upstream/main`
