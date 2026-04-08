---
name: engineering-sop
description: Engineering best practices SOP for the Bull Bitcoin E2E test suite — commit workflow, test development cycle, code review standards
---

# Engineering SOP — Bull Bitcoin E2E Test Suite

## Sources
These principles are drawn from verified sources:
- Kent Beck — Canon TDD, Tidy First? (2023)
- Google Engineering Practices — Small CLs
- Martin Fowler — Test Architecture, Page Object Pattern
- Jake Wharton / Square — Robot Pattern, strict green-before-merge
- VGV (Very Good Ventures) — Robot Pattern for Flutter

## Pre-Session Checklist
1. Check disk: `df -h /` — require >= 30GB free
2. Sync upstream: `git fetch upstream && git rebase upstream/main`
3. Verify emulator: `adb devices` — boot if needed
4. Check working tree: `git status` — commit or stash any uncommitted work

## Development Cycle (per task)
```
1. PICK    — highest-value test scenario from plan
2. WRITE   — write the failing test (Red)
3. PASS    — make it pass with minimum code (Green)
4. REFACTOR — clean up without changing behavior
5. COMMIT  — atomic commit, one logical change, ~100 lines
6. PUSH    — push to fork (friend tracks progress)
7. REPEAT
```

## Commit Standards (Google Small CLs)
- One self-contained change per commit
- ~100 lines ideal, 1000+ too big
- NEVER mix refactoring with feature work — separate commits
- Descriptive message: what changed AND why
- Include Co-Authored-By for Claude-assisted commits

## Test Writing Standards
- All assertion text from `patrol_test/helpers/test_constants.dart`
- Constants sourced from `localization/app_en.arb` — single source of truth
- Use `waitForText()` polling — NEVER fixed sleeps or `pumpAndSettle()`
- Use `$.tester.tap()` for bottom/obscured buttons
- Each robot method does ONE thing — tap, assert, or wait
- Journey tests compose robots — read like user stories
- Run `patrol develop` for iteration, `patrol test` for verification

## Code Organization
```
patrol_test/
  robots/           — one Robot per screen, extends BaseRobot
  journeys/         — compose robots into user story tests
  helpers/          — test_constants.dart + test_helpers.dart
  app_launch_test.dart — smoke tests (fast, basic health check)
```

## Upstream Code Policy (Martin Fowler separation of concerns)
- Test files (`patrol_test/`, `test/`) = our code, no conflict risk
- Infrastructure files (`build.gradle`, `pubspec.yaml`) = shared, watch for merge conflicts
- App source (`lib/`) = upstream code, do NOT modify except:
  - Surgical 1-line ValueKey additions (if widget finding is too fragile)
  - Each ValueKey addition tracked in commit message

## Quality Gates
- All tests green before committing (Jake Wharton / Square principle)
- If a test is flaky, fix or delete it — never normalize flakiness
- Remove duplicate tests when robots cover the same flow (Martin Fowler)
- Property tests (`flutter test test/property/`) run in seconds — use for fast feedback

## Fork Workflow
- `origin` = our fork (push here)
- `upstream` = SatoshiPortal (pull from here)  
- Branch: `e2e-test-suite`
- Push after each phase completion
- Sync upstream weekly or before major work
