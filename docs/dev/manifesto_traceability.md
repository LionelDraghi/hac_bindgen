# Manifesto traceability

Disposition of every section of the original manifesto
(`tools/HAC_Bindgen_Manifesto.md` in the TopoProof repository — the
original stays there, unmodified) into this repository.

Disposition values:

- **Reported** — the content landed, essentially as written, at the
  linked place;
- **Modified** — the content landed with a deliberate change of
  meaning, the change is stated;
- **Superseded** — the content no longer applies, by design decision;
  what replaced it is linked;
- **Deferred** — the content is kept for a later milestone, and is
  referenced from the roadmap so it is not lost;
- **Adapted** — the content landed reshaped (layout, tool conventions).

| Original section | Disposition | Where / what replaced it |
|---|---|---|
| Status (preamble: experimental proposal, independence from any application, potential contribution to the HAC ecosystem) | Reported | [../manifesto.md](../manifesto.md) header and §6 |
| §1 Motivation | Reported | [../manifesto.md](../manifesto.md) §1 |
| §2.1 The Ada specification is the source of truth | Modified | [../manifesto.md](../manifesto.md) §2: the rich API is now the primary input; a hand-written façade stays a valid input ([S005]) |
| §2.2 Input remains plain legal Ada | Reported | [../manifesto.md](../manifesto.md) §3.1, [S005] |
| §2.3 The generator does not bind arbitrary Ada | Modified | split: the *input* may be arbitrary Ada (traversal, [S006]); the *bound* subset stays narrow — "parsing is not binding" in [../manifesto.md](../manifesto.md) §3.4 |
| §2.4 Restriction is a feature | Reported | [S011] |
| §2.5 Generated code must remain inspectable | Reported | [S004] |
| §2.6 No silent conversion | Reported | [S003], [C002] |
| §2.7 The application owns object semantics | Reported | [../manifesto.md](../manifesto.md) §3.5 |
| §2.8 Parsing a construct does not make it bindable | Reported | [../manifesto.md](../manifesto.md) §3.4 |
| §2.9 Real execution is the primary proof | Reported | [../manifesto.md](../manifesto.md) §3.7, [S008] |
| §3 Non-goals | Modified | [../specifications.md](../specifications.md) §6: "derive a scripting façade from a rich API" moved from non-goal to primary goal |
| §4 Terminology | Reported | [../specifications.md](../specifications.md) §5 |
| §5 Overall architecture | Reported (simplified) | [../manifesto.md](../manifesto.md) §5 |
| §6 Processing architecture | Deferred | architecture of the analysis chain detailed at M3; the binding-model boundary is stated in [../manifesto.md](../manifesto.md) §5 and [hac_interfacing_notes.md](hac_interfacing_notes.md) |
| §7.1 CLI executable | Reported | [S010], [A001] |
| §7.2 Analysis backend | Reported | roadmap M3 |
| §7.3 Analysis abstraction | Reported | roadmap M3 (the binding model is the boundary) |
| §7.4 Binding model | Reported | roadmap M3 |
| §7.5 Profile validator | Superseded | no validation gate: traversal classification, warnings ([S006], [B001]) |
| §7.6 Native adapter generator | Reported | roadmap M4, [A002] |
| §7.7 HAC declaration generator | Reported | roadmap M4, [A002] |
| §7.8 Manifest generator | Deferred | roadmap, gadgets (JSON manifest) |
| §8.1/8.2/8.3 Backend candidates and selection principle | Deferred | recorded in [hac_interfacing_notes.md](hac_interfacing_notes.md) and the design discussion of M3; criteria kept in the original manifesto |
| §8.4 GNAT remains the legality authority | Reported | [S012] |
| §9 Generated-file identification | Reported | [S002], [A002-08] |
| §10.1 Minimal generation | Reported | [A001], [A002] |
| §10.2 Explicit generation options | Reported | [A001] planned options |
| §10.3 Validation only (`check`) | Modified | [A001]: `check` reports the bound/not-bound classification; no rejection counts (no rejections exist) |
| §10.4 `verify` command | Deferred | roadmap, gadgets |
| §10.5 Version reporting | Reported | [A001] |
| §10.6 Diagnostic formats | Deferred | roadmap, gadgets (gcc format; SARIF on demand) |
| §11 Input and generated files (examples/geometry) | Adapted | the example package becomes the witness-application input of `tests/` (M2/M4); the generated-file list is in [A002] |
| §12 Example generated native package | Deferred | the M4 templates; the real `HAC_Sys.Interfacing` API is pinned first in [hac_interfacing_notes.md](hac_interfacing_notes.md) |
| §13 Example generated HAC declaration | Modified | the `with Import => True` mechanism (verified form) replaces the speculative package; tracked in [hac_interfacing_notes.md](hac_interfacing_notes.md) |
| §14 Example generated manifest | Deferred | gadget, see [A002] file table and roadmap |
| §15 Initial binding profile (three categories) | Superseded | traversal classification: bound / warned ([S006]) |
| §16.1 One library-level package specification | Reported | [A002] |
| §16.2/16.3 Procedures and functions | Reported | [A002-01], [A002-02] |
| §16.4 `in` parameters | Reported | [A002] profile |
| §16.5 Boolean values | Reported | [A002-04]; mapping route verified in M2 |
| §16.6 Signed integers and subtype range checks | Reported | [A002] profile; range check at [A002-10] and [C002-01] |
| §16.7 Floating-point types | Reported | [A002-03]; HAC representation verified in M2 |
| §16.8 Enumerations | Deferred | M6 (with the invalid-position test of [C002-02]) |
| §16.9 Handles | Deferred | M6; no invented aspect, per [S005] |
| §16.10 Strings | Deferred | M6, after the ownership/lifetime verification of M2 |
| §17.1/17.2 `out` and `in out` parameters | Reported (deferred) | [A002-06], catalogue `HACB0008` |
| §17.3/17.4 Modular and fixed-point types | Reported | catalogue `HACB0010` |
| §17.5/17.6 Records and arrays | Reported | catalogue `HACB0005` |
| §17.7 Default parameter expressions | Reported | catalogue `HACB0009` |
| §17.8 Renamings | Reported | catalogue `HACB0012` |
| §17.9 Native package types | Reported | catalogue `HACB0013` |
| §17.10 Exception identities | Reported | catalogue `HACB0011` |
| §18.1 Generic packages and subprograms | Reported | catalogue `HACB0007` |
| §18.2/18.3 Access types and parameters | Reported | catalogue `HACB0003` |
| §18.4/18.5/18.6 Private, limited, tagged types | Reported | catalogue `HACB0004` |
| §18.7 Interface and class-wide types | Reported | catalogue `HACB0004` |
| §18.8 Tasks and protected objects | Reported | catalogue `HACB0006` |
| §18.9/18.10 Discriminated and anonymous composites | Reported | catalogue `HACB0005` |
| §18.11 Controlled types | Reported | catalogue `HACB0015` |
| §18.12 Native addresses | Reported | catalogue `HACB0014` |
| §18.13 Overloaded exported names | Reported | catalogue `HACB0001` |
| §18.14 Operator symbols | Reported | catalogue `HACB0002` |
| §18.15 Unknown binding annotations | Superseded | no invented aspects exist at all ([S005]); there is no such source construct to reject |
| §18.16 Declarations needing semantic inference | Reported | catalogue `HACB0016` |
| §19 Example: rich API and scripting façade | Modified | §19.1 "not a valid initial input" is obsolete — the rich API is the primary input ([../manifesto.md](../manifesto.md) §2); the façade becomes the optional curated form; the full example is the M2/M4 witness-application reference |
| §19.2/19.3 Façade and implementation | Deferred | kept as the reference for the optional façade form; exercised by [A002] scenarios |
| §19.4 HAC-side program | Modified | the script shape follows the verified `with Import => True` mechanism (M2), not the speculative `Geometry_Scripting_HAC` package |
| §20 Export selection | Superseded | "the supplied package is a scripting façade and all of its profile-compliant subprograms are exported" is obsolete: selection is the traversal result ([S006]) |
| §21.1 Default name mapping | Reported | [A002-11] |
| §21.2 No external-name override | Reported | [A002-11], [S005] |
| §21.3 Collision detection | Reported | [A002-12], [B001] |
| §22 Error model | Reported | [S007] (generation warnings / boundary errors / application errors) |
| §22.4 Exception boundary | Reported | [S007] class 3, [C002-04] |
| §23 Parsing and semantic scope | Deferred | [hac_interfacing_notes.md](hac_interfacing_notes.md), design discussion of M3 |
| §24 Licence evaluation | Reported | concern indexed in [concerns.md](concerns.md), evaluated at M3 |
| §25 Test philosophy | Reported | [S008], [../manifesto.md](../manifesto.md) §4 |
| §26 End-to-end reference chain | Reported | [../manifesto.md](../manifesto.md) §4, [A002] reference shape |
| §26.1/26.2 No mocked HAC or native application | Reported | [S008] |
| §26.3 BBT owns expected behaviour | Reported | [S008], [A002] reference shape |
| §26.4 What one E2E test validates | Reported | [A002] reference shape narrative |
| §27.1 Binding-profile rejection | Superseded | no package rejection exists: warnings replace rejections ([S006], [../manifesto.md](../manifesto.md) §2) |
| §27.2 Runtime-boundary rejection | Reported | [C002], [S007] class 2 |
| §28.1-28.3 Analysis, model, validation tests | Modified | bbt is the single test suite ([S008]); the analysis/model checks run through the CLI, not as unit suites |
| §28.4 Golden-file generation tests | Reported | [A002-07] (byte-identical regeneration) |
| §28.5/28.6 GNAT and HAC compilation tests | Reported | [A002] scenarios compile through both toolchains |
| §28.7 End-to-end execution list | Modified | items 1-13 in [A002] and [C002]; items 14-15 (several packages, repeated execution) in roadmap M6 |
| §28.8 Regeneration test | Reported | [A002-07] |
| §28.9 Version-marker test | Reported | [A002-08] |
| §28.10 No-manual-glue criterion | Reported | [S009], [A002-09] |
| §29 Experimental repository layout | Adapted | the layout follows the ada-project-template tree; the manifest's src/tests/examples roles map to `src/`, `tests/` (witness) and `docs/features/` |
| §30 Stage 0 (verify the real callback surface) | Reported | [hac_interfacing_notes.md](hac_interfacing_notes.md) |
| §30 Stage 1 (hard-coded generator) | Reported | roadmap M1/M4: the CLI harness first, generation then lands |
| §30 Stage 2/3 (minimal prototypes, backend selection) | Reported | roadmap M3 |
| §30 Stage 4 (initial profile validation) | Reported | roadmap M4/M5 |
| §30 Stage 5 (handles and enumerations) | Reported | roadmap M6 |
| §30 Stage 6 (packaging decision) | Deferred | roadmap, gadgets (Alire publication) |
| §31 Acceptance criteria | Reported | [../specifications.md](../specifications.md) §7 |
| §32 Failure criteria | Reported | [../specifications.md](../specifications.md) §8 |
| §33 Design principles for future extensions | Reported | [../specifications.md](../specifications.md) §9 |
| §34 Open questions | Reported | [hac_interfacing_notes.md](hac_interfacing_notes.md) (HAC interfacing, numerics, strings, errors), [concerns.md](concerns.md) and the M3 design discussion (analysis, distribution), [design_discussions.md](design_discussions.md) (generated artefacts); the binding-profile questions resolve through their feature pages ([A002], [B001]) |
| §35 Contribution philosophy | Reported | [../manifesto.md](../manifesto.md) (the tool stays a HAC companion; explicit rejection of clever inference) |
| §36 References | Reported | [../specifications.md](../specifications.md) §10 |
| §37 Final statement | Modified | [../manifesto.md](../manifesto.md) §7: "validates that façade against a documented binding profile" replaced by the traversal contract |

## Orphan check

Nothing in the original manifesto is left unaccounted for. The
superseded items (§2.3-as-rejection, §7.5 gate, §15, §20, §27.1) are
exactly the ones the project direction change removed, and each points
at what replaced it.
