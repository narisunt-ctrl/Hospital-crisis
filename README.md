# Hospital Crisis · เข้าเวรกับ AI

Playable Thai-language emergency-room management prototype, built from the supplied planning documents. Uses Python 3.10+ and browser-native JavaScript; no runtime packages, API keys, or database required.

## Run

```sh
cd /workspace/Hospital-crisis
python3 server.py --port 8000
```

Open the served page in your browser. Select a patient, then assign an available bed and staff team. Both are needed to begin care. Start or pause the clock; complete a three-minute wave. Normal, overload and mass-casualty scenarios share the same engine. Seed controls repeatable arrivals. The assistant proposes one pending allocation; approval is explicit. A human action discards the pending proposal.

## Validate

```sh
python3 -m unittest discover -s tests -v
node --check web/app.js
```

## Implemented

- Server-authoritative seeded simulation; serialized mutations and explicit virtual clock.
- Four validated actions, resource exclusivity, optimistic state version, command idempotency and source attribution.
- Three scenarios, staff and bed management, bounded transfers, urgency escalation, pause and speed controls.
- Rule-based assistant with human approval; wave score, timestamped event log and downloadable JSON run record.
- Responsive Thai interface; static frontend served with same-origin API.

## Toy rules v1

Each wave lasts 180 virtual seconds with 4 beds, 3 teams and 3 partner transfer slots. Scenarios spawn 10/15/20 synthetic patients. Care requires a bed and team for 14–25 virtual seconds. Severity 1/2/3 wait targets are 65/40/20 seconds; exceeding these lowers the safety score. Only severity 1–2 can transfer. Priority may be increased, never lowered below initial severity. These are fictional game mechanics, with no clinical calibration or reviewer approval.

Safety = 100 × fraction not exceeding wait target. Efficiency = 100 × resolved / arrived (transfers count as resolved). Resources = occupied treatment team-seconds / available team-seconds × 100. Waiting = 100 minus average capped urgency-weighted wait penalty (min(100, wait × severity × 2)). Fitness = .40 safety + .25 efficiency + .20 resources + .15 waiting. Live scores are provisional until wave end. Version: `toy-v1`.

## Scope still outstanding

This is a playable vertical slice, not completion of the attached P0 specification. Frontend uses vanilla JavaScript and CSS instead of React/Phaser; backend uses Python standard library instead of FastAPI. There is no Codex SDK integration, actual code evolution, isolated candidate worker, protected 20-case holdout, promotion/rollback registry, persistent game storage, multiplayer, or verified replay. Export is a recorded run, explicitly not a verified replay. Tests cover reproducibility but are not protected benchmark evidence. No improvement claims are made. Sessions are in memory and reset on server restart; capacity is 200 sessions per process. Intended for local development, not public multi-user production deployment. Optional Google Font has system fallback.

Original supplied planning documents are preserved under `docs/planning/`. This code was created before the event date described there; it must not be represented as event-day development.
