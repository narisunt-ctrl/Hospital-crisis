> **Planning update (2026-10-23):** Event is **1 day with 7 judged hacking hours**, not the originally assumed 3 days. This document describes target architecture/test coverage; any missing implementation must be marked honestly. See `docs/SPRINT_PLAN.md`.

# Test Matrix — required checks (none executed yet)

| ID | Test | Expected |
|---|---|---|
| T01 | Start and complete solo ER wave | Completes, result displayed |
| T02 | Same seed + event order + commands + rule versions repeated | Identical event trace and Fitness |
| T03 | Accelerated headless vs normal-paced with same inputs | Identical simulation state |
| T04 | Duplicate `command_id` | Original outcome returned, no double allocation |
| T05 | Wrong `expected_state_version` | Rejected atomically; no state mutation |
| T06 | Two players/AI attempt last bed at same tick | One accepted, resource never duplicated |
| T07 | Human override pending AI decision | Validated, logged, deterministic priority |
| T08 | AI tries to access hidden patient truth | Denied; observation redacted |
| T09 | Codex edit in restricted plugin worktree | Real diff; base/core unchanged |
| T10 | Generated capability registered but never called | Not counted as proven Self-Expanding behavior |
| T11 | Worker attempts to access network/credentials/evaluator | Denied/fails safely |
| T12 | Typed/integration test fails | No promotion, LKG active |
| T13 | Holdout improvement exactly +5% relative and no blockers | Allowed if all other gates pass |
| T14 | Mass Casualty -9 points; overall +5.71% | Rejected by regression guard |
| T15 | Per scenario -5.00 points, other gates pass | Allowed by guard boundary |
| T16 | One simulated critical preventable violation | Rejected |
| T17 | Indeterminate feasibility | Rejected pending evaluation |
| T18 | Worker times out or killed in attempt | Cleanup, persisted failure, LKG remains |
| T19 | 2 attempts used / 5-minute budget expired | Stops cycle, no further retries |
| T20 | Candidate READY mid-wave | Remains on previous plugin until next wave |
| T21 | Controller restarts after READY | No double promotion; version consistent |
| T22 | Replay screen shows recorded evidence | Explicit `VERIFIED REPLAY` label and matching hashes |
| T23 | Developer benchmark vs protected holdout | No data or case details leak to Codex |
| T24 | Baseline zero or scoring version mismatch | Explicit reject/calibration, not fake improvement |
| T25 | Scenario macro-weighting 7/7/6 | Equal archetype weight 1/3 each after per-group mean |

Owners, test framework, and actual results TBD after repository integration. These are planned tests, not passed tests.
