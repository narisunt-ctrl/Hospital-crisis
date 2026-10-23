# Decision Log — Hospital Crisis

> Decisions 1–48: confirmed directly by user. Decisions 49–50: selected by assistant under explicit delegation. **Later factual correction by user: hackathon is one day, not three days; #20 is superseded.** All are design choices, not assertions of implementation.

| # | Decision | Status |
|---:|---|---|
| 1 | Self-Evolving AI เป็นจุดขายหลัก | ยืนยันโดยผู้ใช้ |
| 2 | Self-Modifying + Self-Expanding Capabilities | ยืนยันโดยผู้ใช้ |
| 3 | Autonomous evolution between waves | ยืนยันโดยผู้ใช้ |
| 4 | Multi-Objective Fitness | ยืนยันโดยผู้ใช้ |
| 5 | Controlled Self-Evolution; ห้ามแก้ core evaluator | ยืนยันโดยผู้ใช้ |
| 6 | Human + AI Co-op | ยืนยันโดยผู้ใช้ |
| 7 | Emergency Department Simulator MVP | ยืนยันโดยผู้ใช้ |
| 8 | Hybrid Autonomy; AI งานประจำ, ผู้เล่นควบคุมวิกฤต | ยืนยันโดยผู้ใช้ |
| 9 | Solo-First + Multiplayer Co-op ภายหลัง | ยืนยันโดยผู้ใช้ |
| 10 | Crisis Wave-Based; เป้ารอบ 3–5 นาที | ยืนยันโดยผู้ใช้ |
| 11 | Reproducible Evolution Benchmark | ยืนยันโดยผู้ใช้ |
| 12 | Evolutionary Plugin Architecture | ยืนยันโดยผู้ใช้ |
| 13 | Hybrid Medical Simulation: deterministic/discrete-event + optional LLM narrative | ยืนยันโดยผู้ใช้ |
| 14 | Typed Plugin API + Capability Registry | ยืนยันโดยผู้ใช้ |
| 15 | Local Isolated Evolution Worker | ยืนยันโดยผู้ใช้ |
| 16 | Async Evolution + Safe Promotion เฉพาะขอบ Wave | ยืนยันโดยผู้ใช้ |
| 17 | Multi-Gate Evolution Acceptance | ยืนยันโดยผู้ใช้ |
| 18 | Evolution-First MVP; Multiplayer เต็มรูปแบบ deferred | ยืนยันโดยผู้ใช้ |
| 19 | Web-Based 2.5D: React + Phaser + TypeScript | ยืนยันโดยผู้ใช้ |
| 20 | Hackathon development 3 วัน — **SUPERSEDED** by user correction (competition is 1 day; actual coding 7 hours 10:00–17:00) | ข้อสมมติเดิมถูกแก้ไข |
| 21 | Developers 3–4 คน | ยืนยันโดยผู้ใช้ |
| 22 | Mixed-skilled team | ยืนยันโดยผู้ใช้ |
| 23 | TypeScript frontend + Python FastAPI backend | ยืนยันโดยผู้ใช้ |
| 24 | Server-Authoritative Simulation single source of truth | ยืนยันโดยผู้ใช้ |
| 25 | Deterministic Virtual Clock headless benchmark | ยืนยันโดยผู้ใช้ |
| 26 | Human Override + Safety Gate | ยืนยันโดยผู้ใช้ |
| 27 | Partially Observable AI | ยืนยันโดยผู้ใช้ |
| 28 | Fixed Actions + Extensible Intelligence | ยืนยันโดยผู้ใช้ |
| 29 | Python Codex SDK (AsyncCodex) + isolated worker | ยืนยันโดยผู้ใช้ |
| 30 | Live Evolution + Verified Replay Fallback | ยืนยันโดยผู้ใช้ |
| 31 | 20 Paired Seeds; relative +5% Fitness; zero critical; no safety regression | ยืนยันโดยผู้ใช้ |
| 32 | Bounded Evolution: ≤2 attempts, ≤5 minutes per cycle | ยืนยันโดยผู้ใช้ |
| 33 | 4 Actions: assign_staff, allocate_bed, prioritize_queue, request_transfer | ยืนยันโดยผู้ใช้ |
| 34 | Unified Typed Command Contract, command_id, expected_state_version, atomic validation | ยืนยันโดยผู้ใช้ |
| 35 | Local-First Demo | ยืนยันโดยผู้ใช้ |
| 36 | Role-Separated Evolution Control | ยืนยันโดยผู้ใช้ |
| 37 | Fault-Tolerant State Machine + LKG | ยืนยันโดยผู้ใช้ |
| 38 | Verifiable Evolution Demo with working, failed-path, replay evidence | ยืนยันโดยผู้ใช้ |
| 39 | End-to-End Vertical Slice approach, **adapted to 7-hour sprint** | ยืนยันโดยผู้ใช้ (ใช้วิธีเดิม) |
| 40 | Early Vertical Slice + real Codex Smoke Test, **during first stage of event day** | ยืนยันโดยผู้ใช้ (ปรับเวลา) |
| 41 | Risk-Based Feature Freeze P0 / P1 / P2 | ยืนยันโดยผู้ใช้ |
| 42 | Hard Go/No-Go Gates, **now intraday checkpoints** | ยืนยันโดยผู้ใช้ (ปรับเวลา) |
| 43 | Development Benchmark + protected Blind Holdout | ยืนยันโดยผู้ใช้ |
| 44 | Two-Layer Safety Gate: System + Simulated Patient | ยืนยันโดยผู้ใช้ |
| 45 | Feasibility-Aware Safety with indeterminate cases blocked | ยืนยันโดยผู้ใช้ |
| 46 | Three Scenario Archetypes: Normal, Overload, Mass Casualty | ยืนยันโดยผู้ใช้ |
| 47 | Stratified 20 Seeds 7/7/6; equal scenario weighting; regression guard | ยืนยันโดยผู้ใช้ |
| 48 | Maximum 5-point mean Fitness regression per scenario (0–100 scale) | ยืนยันโดยผู้ใช้ |
| 49 | Fixed Normalized Weighted Fitness: S40 E25 R20 W15; hard Safety Gate separate | เลือกโดยผู้ช่วยตามที่มอบหมาย |
| 50 | Version-locked, deterministic subscore rubric; freeze normalizers and scenario targets before hidden testing; report component scores and all blockers | เลือกโดยผู้ช่วยตามที่มอบหมาย |

## Time and judging addendum — 23 October 2026
- Official event: **21 November 2026**, hacking from **10:00 to 17:00**, code freeze at 17:00. Registration closes **23 October 2026 23:59** (Luma, https://luma.com/39zve8ph).
- The user corrected the earlier 3-day timeline: **one day**. This supersedes #20 but preserves other decisions as intended architecture, not a promise of full implementation in seven hours.
- Split scope into **7-hour judged vertical slice** versus **deferred full vision**. Use intraday gates, not D1/D2/D3 gates.
- **Compliance:** New, substantive code must be written at the event. Prior design notes and legally permitted pre-existing code must be identified truthfully; do not misrepresent development chronology.

## Still open / calibration needed

- นิยามเชิงตัวเลขของ 4 subscores, baseline/normalizers และ event-level patient-safety rules ต้องทดสอบและ freeze ก่อน Holdout (decision #50 chooses the process, not fabricated clinical thresholds).
- จำนวน Development Seeds และสำรอง Blind Holdout สำหรับหลายรอบการทดลองยังไม่กำหนด.
- ความพร้อมของเครื่อง Demo, Codex authentication, connectivity และ costs ยังไม่ได้ยืนยันด้วยการรันจริง.
- เวลา 3–5 นาทีต่อ Wave และ 5 นาทีต่อ Evolution Cycle เป็นขอบเขตต้นแบบ ไม่รับประกันว่าจะใช้เวลาเท่านี้.
- ขอบเขตขั้นสุดท้ายขึ้นกับ Milestone gates; ห้ามแทนผลสดด้วย replay โดยไม่ติดป้าย.

## Deferred

- Multiplayer network sync/UI (ออกแบบเผื่อ 2–3 players แต่ไม่ใช่ P0).
- Expanded hospital departments (OPD, ICU, wards), richer clinical cases, full 3D, audio and cutscenes.
- Research-grade statistical validation and independent clinical validation before any real-world use.
