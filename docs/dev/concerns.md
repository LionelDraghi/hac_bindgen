# Concerns

This is a lightweight index, not a duplicate issue tracker. Each row
supplies priority, a short label, kind, authoritative link, and status;
the details remain in the authoritative source.

| Priority | Concern | Kind | Source | Status |
|---|---|---|---|---|
| P2 | Analysis-backend licensing must be evaluated before the backend is selected (components used, licence text, linking, distribution alongside HAC) | Design | to record in [design_discussions.md](design_discussions.md) at M3 | Open |
| P2 | The `with Import => True` declaration mechanism in a package specification is unverified | Design | [hac_interfacing_notes.md](hac_interfacing_notes.md) | Open |
| P3 | Boolean has no direct `To_HAC` overload: mapping route (generic enum vs Integer) to be tested and fixed | Design | [hac_interfacing_notes.md](hac_interfacing_notes.md) | Open |

## Adding a concern

- P1: blocks normal use, threatens correctness, breaks CI or release,
  or creates material risk;
- P2: important and actionable but not immediately blocking;
- P3: worthwhile maintenance or improvement with limited current impact.

Kinds: Bug, Debt, Design, Quality. The Source column points to the
authoritative place — an issue, a pull request, a proposal, a generated
report. A closed concern is removed or marked closed according to the
project's desired history policy.
