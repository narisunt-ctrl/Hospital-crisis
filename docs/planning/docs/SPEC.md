# Product & Engineering Specification — Hospital Crisis: เข้าเวรกับ AI

> **Draft for spec handoff**, 2026-10-23; not repository-grounded and not implemented. Source of decisions: current `/grill-me` conversation and `docs/DECISION_LOG.md`.

## 1. Product statement
Web browser ER crisis management game with **human + AI cooperative decision-making**, proving a bounded self-evolving software agent can improve code-backed operational strategy. Demo differentiator: show the **real code diff, independent benchmark, safety decision, and wave-boundary promotion**. Educational fiction with synthetic patients; not a patient-care tool.

## 2. Constraints and priorities
- Hackathon **1 day, 21 Nov 2026**, with **7 hours of judged hacking (10:00–17:00)**; **3–4 developers** of mixed skills. Application deadline **23 Oct 2026 23:59**. Supersedes previous 3-day planning assumption.
- **P0:** end-to-end playable single-player ER simulation; fixed action API; Codex real patch; isolated candidate verification; reproducible protected benchmark; safety gates; safe promotion/rollback; verified evidence/replay.
- **P1 (degrade if behind):** visual polish for **2.5D React + Phaser**, animation, large patient counts and UI nuance.
- **P2 (defer):** networked multiplayer, sound, cutscenes, hospital decoration, multiple departments and extra clinical scenarios.
- **Feature-freeze rule:** at failed **intraday integration/evolution checkpoints**, stop work on P1/P2 and resolve P0 critical path.

## 3. Player experience
- **Solo-First:** one human manages ER in real-time-feeling **3–5 min crisis waves**. Game model is 2.5D/isometric style but may have placeholders to protect P0.
- **Hybrid Autonomy:** AI handles routine queue / staff / bed / transfer choices; player handles crises, policy choices and may override **pending** AI commands. The validator remains authoritative.
- **Archetypes:** Normal ER Operations; ER Overload; Mass Casualty Incident. Synthetic patient data, deterministic event transitions. LLM only adds optional language/narration, never ground truth or medical outcomes.
- **End of wave:** show operational scores and evolution status; start asynchronous Evolution Cycle with latest report. Allow next wave with LKG; activate passing candidate only at future wave start.
- **Co-op:** 2–3 players is a future mode; do not claim playable in MVP unless built.

## 4. Core functionality
- **Game State:** stored/updated only by Python simulation authoritative process. Browser sends validated commands and renders snapshots/events.
- **Time:** deterministic event queue + seeded RNG + explicit order rule for same-time events; virtual clock supports headless accelerated evaluation. Record action time, source, state version, and reproducibility data. Do not let external LLM latency change virtual time.
- **Partially observable:** `ObservationV1` exposes only revealed patient data, queue, resources and present events. Hidden patient ground truth, future events and protected benchmark unseen by AI and Codex patch workspace.
- **Actions:** fixed `assign_staff`, `allocate_bed`, `prioritize_queue`, `request_transfer`. No direct treatment recommendations or dynamic new action types in MVP.
- **Commands:** typed discriminated union with `command_id`, `actor_id`, `expected_state_version`, `action`, `payload`. Server idempotency + atomic compare-and-apply + role checks + appended audit event. Failed validation must not change game state.
- **Human override:** replaces not-yet-committed AI command and must satisfy the same safety checks. Benchmarks run AI-only without uncontrolled human input; co-op scores separate.

## 5. Evolution architecture
- `AsyncCodex` through official Python `openai-codex` SDK in Controller. Authenticate at backend, not browser. Use isolated patch worktree; allow write only to strategy/capability modules.
- **Plugin API + Capability Registry:** code-defined `decide(ObservationV1) -> ActionV1[]`; new predictive / planning capability must be registered, invoked and shown to affect an actual decision. Core simulation, hidden evaluator and action vocabulary immutable to candidate.
- **Candidate runner isolation:** separate worker/container with low privileges, no network/secrets, resource/time bounds and read-only input mounts. Codex Controller is separate from the untrusted code runtime.
- **Async job lifecycle:** QUEUED -> RUNNING -> TESTING -> READY / FAILED / TIMEOUT -> (at wave boundary) PROMOTED. Persist state (SQLite suggested). Fail closed to LKG; retry within **max 2 attempts / max 5 min per cycle**; no silent infinite retry. Ensure promotion atomic/idempotent after process crash.
- **Safe Promotion:** correctness + contract + integration + system-safety + simulated-patient-safety + fitness + regression gates. No replacing plugin mid-wave.

## 6. Evaluation contract
- One **shared simulator** for gameplay and headless evaluation; scenario/metric versions frozen before protected holdout.
- **Stage 1** Development Benchmark returns actionable diagnostics to Codex.
- **Stage 2** protected Blind Holdout: **20 paired seeded cases**: **7 Normal, 7 Overload, 6 Mass Casualty**. Same paired seeds for incumbent/candidate; **equal weight per archetype** after first averaging within archetype.
- Normalized Fitness from 4 subscores (0–100): `F = 0.40*S + 0.25*E + 0.20*R + 0.15*W`, where S=patient safety (simulated), E=treatment efficiency, R=resource optimization, W=waiting-time score. This is assistant-selected **#49**, requested delegation.
- Component functions, caps, denominators, scenario targets and virtual-time checkpoints must be deterministic, versioned and frozen before final Holdout. No inventing clinical thresholds; confirm toy-simulator rule choices with domain reviewer.
- **Promote only if**: relative mean Fitness gain **>= 5%** vs incumbent, **zero critical safety violations**, no safety regression and **each archetype's mean Fitness loss <=5 points (0–100)**. Use equal-weight means for overall. Baseline-zero and missing/uncomparable metric versions are explicit reject/calibration conditions.
- **Critical safety:** System Safety (resources cannot double assign, invalid actions cannot mutate state, access boundary) + Simulated Patient Safety (avoidable violation of defined urgency/capability rules). Unavoidable adverse outcomes still penalize Fitness when appropriate but do not auto-create critical fault; ambiguous preventability -> **reject pending investigation**.
- No hidden seed, per-case Holdout feedback or evaluator code is mounted to Codex workspace/candidate. Limit repeated probing of fixed holdout. Results are **MVP heuristic evidence**, not statistical/clinical proof.

## 7. Game/UI surfaces
1. **ER 2.5D Play Screen:** queue cards / available beds / staff / simulation clock / pending suggestions / safe override UI.
2. **Wave Results:** 4 subscore cards, overall Fitness, critical violations, scenario.
3. **Evolution Panel:** job state, attempts, remaining budget, current/candidate version ids, capability diff, code diff summary, gate results, PASS/FAIL reason.
4. **Evidence Replay Screen:** labeled `LIVE` or `VERIFIED REPLAY`; timestamp, code commit hash, scenario version, metric version, reproduced Fitness report, event log.

## 8. Definition of Done (Release Gate on event day)
- One Wave fully playable Solo, simulated event state reproducible for same seed and action trace.
- Codex can **actually** modify restricted Strategy Plugin, produce code diff, pass tests, with evidence of one new *used* capability.
- At least one actual candidate from testing passes approved criteria (20 protected paired seeds, >=5% relative gain, all safety gates, per-scenario regression guard), with reproducible report; if none, mark criterion **not met** truthfully.
- Fail candidate blocked; LKG remains playable; worker timeout cleanup and transition tested.
- Replay from actual recorded run and clearly labeled, not presented as live.
- Source and tests are **not implemented by this Markdown package**; Definition of Done is a future verification checklist.

## 9. 7-hour Go/No-Go gates
- **10:00–11:00:** confirm environment, Codex access, minimal frontend/API, scratch edit smoke; freeze graphics if integration blocked.
- **11:00–12:30:** deterministic ER loop, one visible scenario, four fixed actions as feasible, initial plugin, seeded headless scoring.
- **12:30–14:00:** Codex patch real strategy plugin in isolated worktree; basic worker tests and version safety.
- **14:00–15:30:** 20 paired 7/7/6 protected evaluation, 5% gate, -5-point per-scenario guard, rejection path; verify baseline and candidate.
- **15:30–16:30:** stability, live code diff, rollback/replay evidence, simplified visual polish.
- **16:30–17:00:** freeze, package submission, smoke demo; organizer code-freeze at 17:00.
- Preserve every unimplemented P0 requirement in an honest checklist, rather than claiming it passed. No pre-event code represented as judged-day development.

## 10. Event compliance and scope realism
- Official policy permits bringing ideas or previously existing personal/open-source projects, but new development assessed by judges must be **substantial and carried out during the event** (https://luma.com/39zve8ph).
- A complete two-stage, protected evaluator and secure worker in seven hours is ambitious. **Do not claim production-grade isolation** unless observed on the event machine. If necessary present an honestly scoped demo with missing checks clearly disclosed.
- Preserve the three archetypes for benchmarks via compact fixtures; one polished playable scenario is enough for visible gameplay. Other scenarios can be headless in the 7-hour MVP.
- Only verify actual Codex capabilities and improvement, never invent uplift, benchmarks, or live completion.

## 11. Open risks / assumptions
- Numeric definition and calibration of 4 subscores and scenario feasibility rules need early design + reviewer; no legitimate medical validation has been conducted.
- 20 seeds / 6–7 per stratum may be noisy; threshold is competition MVP, not significance test. Hidden holdout repeated testing can still overfit.
- Codex SDK authentication/network/environment and external cost have not been tested. Local-first needs working connectivity during live demo.
- Real-world multiplayer remains deferred; LLM narrative may be dropped if costs, safety, or latency threaten P0.
- Game-state persistence, event ordering and sandbox restrictions must be validated on the actual demo machine.

## 12. Handoff to implementation
Read `GLOSSARY.md`, `docs/DECISION_LOG.md`, 3 ADRs, `docs/ARCHITECTURE.md`, `docs/BENCHMARK_AND_SAFETY.md`, `docs/SPRINT_PLAN.md`, and `docs/TEST_MATRIX.md`. Reconcile against actual repo before writing production code. Use explicit failing acceptance tests rather than claiming system already works.
