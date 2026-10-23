# ADR 0002 — Controlled Code Evolution through Isolated Plugins

- **Status:** Accepted design (user decisions #2, #5, #12, #14–17, #28–29, #32–37); **not implemented**
- **Context:** Codex must edit real code and create usable capabilities, but must not alter game rules, evaluation, or hidden seeds, and cannot be allowed to crash live game.
- **Decision:** Fixed, typed Action API; extensible Strategy Plugin and Capability Registry. AsyncCodex in Controller patches scoped worktree; untrusted Candidate executes in isolated Worker with no network or secrets. Controller budgets <=2 attempts and <=5 minutes, tracks durable jobs, runs multi-gate tests, and promotes at new wave only. Fail closed to Last Known Good.
- **Alternatives:** Directly edit entire codebase (showy but unsafe/unreliable); in-process hot-reload (less overhead but risks live state); pure prompt-only adaptation (not true self-modifying code).
- **Consequences:** Additional integration/isolation work; auditability, rollback, future capabilities, and controlled blast radius.
- **Why ADR:** Decisive module/trust boundaries are expensive to change; creates surprising limitation that AI cannot invent Action types; clear safety-versus-freedom tradeoff.
