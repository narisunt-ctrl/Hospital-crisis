# Hospital Crisis: เข้าเวรกับ AI — Grill Handoff

> **สถานะ:** Revised one-day hackathon handoff, 2026-10-23. User corrected the event duration AFTER the 50-decision grill. **ไม่เคยนำไปเขียนใน Git repository ของโครงการ**; ไม่มี project source code, GLOSSARY.md, GLOSSARY-MAP.md หรือ ADRs ของโครงการให้ตรวจสอบขณะจัดทำนี้. This package is a proposed file tree for later application and reconciliation with a real repository.

## ที่มาและอำนาจตัดสินใจ
- Decisions **1–48**: ผู้ใช้เลือกยืนยันในบทสนทนา `/grill-me`.
- Decisions **49–50**: ผู้ใช้มอบหมายให้ผู้ช่วยเลือกเพื่อปิดกระบวนการ; เป็น **assistant-selected/delegated** ไม่ใช่คำตอบที่ผู้ใช้เลือกด้วยตนเอง.
- ไม่มี code implemented, tests executed, claims of actual benchmark improvement, or autonomous Codex run.
- การวิเคราะห์ต่อไปนี้เป็น game simulation (synthetic patients) ไม่ใช่เครื่องมือวินิจฉัยหรือให้การรักษาผู้ป่วยจริง.

## File map
- `GLOSSARY.md` — คำศัพท์โดเมนที่ตกลงกัน (คำจำกัดความเท่านั้น)
- `docs/DECISION_LOG.md` — 50 decisions และสถานะ
- `docs/SPEC.md` — สเปก MVP และ acceptance criteria
- `docs/ARCHITECTURE.md` — ส่วนประกอบ / ขอบเขต / Typed API contract
- `docs/BENCHMARK_AND_SAFETY.md` — metrics, multi-gate, integrity, safety rules
- `docs/SPRINT_PLAN.md` — **7-hour competition** roadmap for 3–4 people; pre-event preparation vs judged new development
- `docs/TEST_MATRIX.md` — เกณฑ์ทดสอบที่ต้องดำเนินการ
- `docs/APPLICATION_DRAFT.md` — ข้อความสมัครทีมวันนี้ (English/Thai) และ checklist
- `docs/adr/` — ADR เฉพาะข้อสรุปที่ยากต่อการย้อนกลับ มี trade-offs และไม่ชัดเจนหากไม่บันทึกเหตุผล

## Official event correction (supersedes earlier 3-day assumption)
- **Application deadline:** Friday **23 October 2026, 23:59 Thailand time**. **Every member must register separately** with the **exact same team name**; 3–4 members, max 40 teams; selection based on application quality, technical background, intended build.
- **Event:** Saturday **21 November 2026**, Singha Complex, Bangkok. Actual hacking **10:00–17:00 (7 hours)**; code freeze/submissions **17:00**. Results announced by 9 November.
- Official registration: https://luma.com/39zve8ph
- Organizer permits preparing ideas and bringing existing personal/open-source projects, but **substantial new judged work must be developed during the event**. Do not represent pre-event code as new competition work.
- Earlier grill choice #20 of "3 days" was based on an incorrect assumption; the user corrected it. Decisions #39–42 refer to an end-to-end/Go-No-Go *method*, now compressed into checkpoints during a single day.

## ขอบเขต MVP ที่สำคัญที่สุด
1. Solo-first ER simulator 2.5D, Wave ~3–5 นาที, synthetic cases, AI-assist + human override.
2. Real Codex code patch to Strategy Plugin; Python SDK; separate worker; safe version switching between waves only.
3. Benchmark using the **same deterministic simulation engine**; development tests separate from protected, stratified 20-seed paired holdout.
4. A candidate is promoted **only if all gates pass**. The game continues with Last Known Good Plugin on failure.
5. Replay from verified real logs is explicitly labeled as replay (not a fake live run).

## Application-first priority
Use `docs/APPLICATION_DRAFT.md` **today** before deadline. Confirm same exact team name on all 3–4 individual applications. This file contains suggested copy, not facts about each individual's credentials.

## Next usage
นำชุดไฟล์นี้เข้า **repository จริงหลังตรวจสอบโค้ดและเอกสารที่มีอยู่** ก่อน commit. ถ้า repo มี GLOSSARY / ADR อยู่แล้ว ให้ reconcile ก่อนรวม ห้าม overwrite อัตโนมัติ. จากนั้น convert `docs/SPEC.md` -> small tasks -> implementation -> code review.

## Technical verification
Codex Python SDK official getting started: https://github.com/openai/codex/blob/main/sdk/python/docs/getting-started.md (Python >=3.10, `pip install openai-codex`, `AsyncCodex`). SDK is an integration proposal, not executed or verified in this project.
