# Concerns

This is a lightweight index, not a duplicate issue tracker. Each row
supplies priority, a short label, kind, authoritative link, and status;
the details remain in the authoritative source.

| Priority | Concern | Kind | Source | Status |
|---|---|---|---|---|
| P2 | Complete the license/redistribution review of the Libadalang dependency closure (GNATCOLL crates: `GPL-3.0-or-later WITH GCC-exception-3.1`, initial inventory only) | Design | [design_discussions.md](design_discussions.md#analysis-backend-evaluation) | Open |
| P2 | Settle the Libadalang version against the GNAT 16 minimum: 26.0.0 resolves to GNAT 15, 25.0.0 selects GNAT 16.1.0 but is unbuilt against hac_bindgen | Design | [design_discussions.md](design_discussions.md#analysis-backend-evaluation) | Open |
| P2 | The `with Import => True` declaration mechanism in a package specification is unverified | Design | [hac_interfacing_notes.md](hac_interfacing_notes.md) | Open |
| P3 | Boolean has no direct `To_HAC` overload: mapping route (generic enum vs Integer) to be tested and fixed | Design | [hac_interfacing_notes.md](hac_interfacing_notes.md) | Open |

Closed:

| Concern | Closed | Evidence |
|---|---|---|
| Backend selection needs prototype, Ada-coverage, semantic-resolution, and license/redistribution checks for both candidates | 2026-10-29 | Both prototypes built and compared on `tools/*/probe_fixture.ads`; Libadalang selected — [design_discussions.md](design_discussions.md#analysis-backend-evaluation) (license review split into its own open concern) |

## Adding a concern

- P1: blocks normal use, threatens correctness, breaks CI or release,
  or creates material risk;
- P2: important and actionable but not immediately blocking;
- P3: worthwhile maintenance or improvement with limited current impact.

Kinds: Bug, Debt, Design, Quality. The Source column points to the
authoritative place — an issue, a pull request, a proposal, a generated
report. A closed concern is removed or marked closed according to the
project's desired history policy.
