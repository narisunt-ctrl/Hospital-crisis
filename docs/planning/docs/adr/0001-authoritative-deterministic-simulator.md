# ADR 0001 — Server-Authoritative Deterministic Simulation

- **Status:** Accepted design (user decisions #23–25); **not implemented**
- **Context:** Frontend is browser game, yet exact replay and comparable AI fitness require one simulation model; competing browser and backend rules would drift.
- **Decision:** FastAPI/Python owns authoritative Game State, game transition rules and virtual clock. React/Phaser renders and sends typed commands. A single deterministic simulation core powers interactive waves and accelerated headless benchmark.
- **Alternatives:** Client-authoritative Phaser simulation (simpler feeling but untrusted/different benchmark); hybrid dual simulation (less latency, more drift complexity).
- **Consequences:** Slightly more network/API work and latency management; deterministic event ordering, testable replay and cleaner future multiplayer.
- **Why ADR:** Reversing requires rewriting authority and replay models; surprising for many game-engine implementations; meaningful tradeoff between UI simplicity and benchmark integrity.
