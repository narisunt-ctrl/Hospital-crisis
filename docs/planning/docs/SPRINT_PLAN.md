# One-Day Hackathon Sprint — 21 November 2026 (7 hours of hacking)

> **Supersedes the 3-day sprint.** Official event source: https://luma.com/39zve8ph. Participants arrive by 09:00; hacking starts 10:00; **code freeze/submission is 17:00**; judging starts 17:15. 3–4 developers. This is an ambitious scope plan, not an assertion that features are already built.

## Immediate priority: apply by Friday 23 October 2026 23:59 (Thailand)
1. Agree on **exact team name** and secure **3–4 participants**.
2. Each participant **registers individually** at https://luma.com/39zve8ph and types the **exact same team name**.
3. Position the idea primarily as **Autonomous & Adaptive AI**, secondarily **Deep Domain AI**; use clear build story and real team skills.
4. Clearly describe what will be built during the competition; don't represent plans/prototypes as already working.
5. Confirm that all team members submitted successfully. Organizers announce selection by 9 November 2026.

## Before event (allowed preparations, do not misrepresent judged work)
- Finalize concept, diagrams, user stories, typed API contract, benchmark rule book, task assignment, and demo narrative; read organizer rules.
- Confirm laptops/chargers and tools for use during the event; rehearse team handoffs and learn APIs on disposable non-submission examples.
- You may bring lawful pre-existing personal/open-source code as allowed by organizers; document what is pre-existing. The rules require substantial new development **on the event day**; only work completed during event is judged.
- Avoid implementing the judged project in advance and passing it off as fresh event work.

## Event day: timeboxed work
| Thailand time | Phase | Deliverable and hard gate |
|---|---|---|
| **09:00–10:00** | Setup/briefing, not judged hacking | log in, verify power/network, task allocation; respect start time |
| **10:00–11:00** | Bootstrap & Codex smoke | React view / FastAPI connect, real `AsyncCodex` scratch edit + check access, simple API schema |
| **11:00–12:30** | Playable deterministic slice | one visible ER crisis wave; seeded events and initial action/plugin + baseline score. Three archetypes may start as headless fixtures |
| **12:30–14:00** | Real evolution | Codex changes real plugin code in restricted candidate workspace; diff and tests; safe candidate isolation |
| **14:00–15:30** | Evidence/gates | compare old vs new on 20 protected paired seeds (7/7/6), verify +5% aggregate, -5-point guard and zero criticals; demonstrate rejection of unsafe candidate |
| **15:30–16:30** | Demo polish & fallback | show before/after; safe-promotion at wave start; fault fallback/LKG; label replay **VERIFIED REPLAY** if used |
| **16:30–17:00** | Freeze and submit | integration smoke test, submit before 17:00, pitch rehearsal |

## Roles (3–4 members)
- **Dev 1:** Game UI + Phaser 2.5D (fallback to simple 2D dashboard if slipping).
- **Dev 2:** authoritative FastAPI simulation + seeded scenarios + scoring and rules.
- **Dev 3:** Codex SDK controller + versioned plugin + isolated worker + benchmark.
- **Dev 4, if present:** tests/integration, event log/replay, pitch/evidence. If 3, split integration among all.

## Go/No-Go gates within the day
- **11:00:** if Codex smoke/access fails, prioritize remediation and show local verified-code fallback truthfully; pause polish.
- **12:30:** if engine/API not integrated, freeze extra scene art and implement compact playable UI.
- **14:00:** if real patch pipeline fails, reduce all nonessential features; do not simulate real Codex run deceptively.
- **15:30:** if candidate fails protected gates, keep current version; do not relax criteria or use fabricated uplift.
- **16:30:** freeze all new features. Stability and truthful submission take priority.

## Reality check and road map
- **P0 minimum story:** one visible ER wave, versioned AI strategy, real Codex code diff, repeatable old-vs-new assessment, safety decision, safe keep/rollback and clear evidence.
- **P1 simplified:** isometric room assets, extra animation, narrative LLM, richer dashboard.
- **Deferred**: functioning multiplayer; departments beyond ER; 3D; extended clinical workflows; enterprise-grade deployment.
- Complete two-stage blind testing + container isolation + 20 paired seeds is **stretch P0** for seven hours. Do not assert claims the team cannot verify. The user-selected design contract remains the long-term target even if competition prototype is reduced.
