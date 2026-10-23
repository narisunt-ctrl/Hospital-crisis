# ADR 0003 — Protected Stratified Benchmark and Multi-Gate Promotion

- **Status:** Accepted design (user decisions #4, #11, #17, #31, #38, #43–48; delegated #49–50); **not implemented**
- **Context:** Comparing live Wave scores gives misleading signals; protected evaluation is required to distinguish real improvement from easier scenarios and manipulation. Safety and scarce resources complicate scoring.
- **Decision:** Two-stage development vs protected holdout; 20 paired hidden seeds stratified Normal/Overload/Mass 7/7/6, equal macro weights; Fitness weighted S40 E25 R20 W15 (delegated). Promotion if >=5% relative overall gain, no more than 5-point regression per archetype, zero critical violations, no safety regression, and all code/integration gates pass. Feasibility-aware two-layer safety; unknown feasibility blocks automatic promotion. Freeze rubric/version before hidden test.
- **Alternatives:** Single public benchmark (fast, high overfit risk); pure global weighted score (may hide severe-case regressions); large statistical suite (more rigorous, too costly for seven judged hacking hours).
- **Consequences:** Higher work in protected evaluator, limited evaluation attempts, and noise with only 6–7 samples per archetype. Makes demo claim more defensible but not research-grade or clinically validated.
- **Why ADR:** Hard to unwind metric/seed design once project builds on it, surprising macro-weighting and hard gates, real tradeoffs between reliability and speed.
