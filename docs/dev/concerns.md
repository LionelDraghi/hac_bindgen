# Concerns <!-- omit from toc -->

This is a lightweight index, not a duplicate issue tracker. Each row
supplies priority, a short label, kind, authoritative link, and status;
the details remain in the authoritative source.

| Priority | Concern | Kind | Source | Status |
|---|---|---|---|---|
| P2 | Complete the license/redistribution review of the Libadalang dependency closure (GNATCOLL crates: `GPL-3.0-or-later WITH GCC-exception-3.1`, initial inventory only) | Design | [design_discussions.md](design_discussions.md#analysis-backend-evaluation) | Open |
| P3 | Upstream the `libgpr2` GNAT 16 port once stabilized, so Libadalang can eventually link into the main crate | Design | [design_discussions.md](design_discussions.md#analysis-backend-evaluation) | Open |
| P3 | `Hac_Bindgen.Model` does not carry format-1 facts that no consumer needs yet: enum literals, static constraints and values, default parameter expressions (HACB0009 stays undetectable); type categories and unhandled kind names are carried since the B001 traversal; add the rest when M5/M6 consumers need them | Design | [design_discussions.md](design_discussions.md#interchange-format-between-backend-and-main-crate) | Open |
| P2 | The `with Import => True` declaration mechanism in a package specification is unverified | Design | [hac_interfacing_notes.md](hac_interfacing_notes.md) | Open |
| P3 | Boolean has no direct `To_HAC` overload: mapping route (generic enum vs Integer) to be tested and fixed | Design | [hac_interfacing_notes.md](hac_interfacing_notes.md) | Open |

Closed:

| Concern | Closed | Evidence |
|---|---|---|
| Backend selection needs prototype, Ada-coverage, semantic-resolution, and license/redistribution checks for both candidates | 2026-10-29 | Both prototypes built and compared on `tools/*/probe_fixture.ads`; Libadalang selected — [design_discussions.md](design_discussions.md#analysis-backend-evaluation) (license review split into its own open concern) |
| Freeze the textual dump format between `tools/libadalang_backend` and the main crate before backend #1 consumes it | 2026-10-30 | Format 1 frozen: the backend and the main-crate reader (`Hac_Bindgen.Dump_Reader`) implement the same grammar, pinned by the [A003 scenarios](../features/A003_interchange_dump.md); any change now requires a format bump |

## Adding a concern

- P1: blocks normal use, threatens correctness, breaks CI or release,
  or creates material risk;
- P2: important and actionable but not immediately blocking;
- P3: worthwhile maintenance or improvement with limited current impact.

Kinds: Bug, Debt, Design, Quality. The Source column points to the
authoritative place — an issue, a pull request, a proposal, a generated
report. A closed concern is removed or marked closed according to the
project's desired history policy.
