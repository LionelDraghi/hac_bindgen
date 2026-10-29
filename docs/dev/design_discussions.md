# Design discussions

This document records structural choices, alternatives, rationale, and
status. It does not duplicate behavioral specifications. An open
decision may be indexed as a concern when it blocks work or creates
material risk.

| Decision | Status | Date |
|---|---|---|
| Parser-independent binding model contract | Accepted | 2026-10-29 |
| Analysis backend: Libadalang vs Dmitry Kazakov's Ada Syntax Analyzer | Discussing | 2026-10-29 |
| HAC declaration mechanism: `with Import => True` placement (nested vs package spec) | Discussing | 2026-10-29 |
| Boolean mapping route: generic enum vs Integer | Discussing | 2026-10-29 |
| Manifest design (generated artefacts policy): check-in policy, generation during builds, source hashes, version coupling, JSON format | Discussing | 2026-10-29 |

Statuses: Discussing | Accepted | Rejected | Superseded.

### Parser-independent binding model contract

Status: Accepted
Date: 2026-10-29
Related: [M3 binding model proposal](../proposed/binding_model.md)

## Context

Analysis and generation need a shared API representation that does not
expose parser-specific nodes. S006 also requires every public
declaration to be accounted for, including declarations that cannot
be bound.

## Options considered

### Classification embedded in each declaration

- Benefits: declaration and its decision are always adjacent.
- Costs and risks: mixes parsed source data with a later analysis
  decision; awkward to retain the same source model across analysis
  passes.

### Separate analysis result linked by declaration identity

- Benefits: preserves the parsed API unchanged and allows the result
  to be validated for complete, unique coverage.
- Costs and risks: consumers must join results to declarations.

## Decision

Use a parser-independent model of all public declarations and a
separate classification result referring to each declaration by a
model-local identity. Store source locations as file path, line, and
column. Type references retain their resolution state and subtype
chain, including partial information where available.

## Rationale

The separate result cleanly distinguishes source facts from binding
decisions and makes S006 completeness mechanically verifiable. File
paths and point locations are sufficient for current package
specifications and actionable warnings. Explicit resolution state
prevents incomplete backend information from being mistaken for a
supported type.

## Consequences

- Analysis backends must populate canonical names and model-local
  declaration identities without exposing parser nodes.
- Before downstream use, validation checks every declaration has
  exactly one result and every warning has its required identifier,
  location, and reason.
- Backend selection and licensing remain open and are tracked
  separately.

### Analysis backend evaluation

Status: Discussing
Date: 2026-10-29
Related: M3; [binding model proposal](../proposed/binding_model.md);
[backend licensing concern](concerns.md)

## Context

The backend must parse ordinary Ada source and provide enough semantic
information to build the parser-independent model. The project currently
requires GNAT 16 or newer. The two candidates are established Ada
analysis libraries; the comparison is about syntax coverage, semantic
queries, integration, and licensing, not whether to write a parser.

## Options considered

### Libadalang

- Benefits: the library has an Ada API, an Alire crate, and on-demand
  name and type resolution.
- Costs and risks: tagged release documentation for both 25.0.0 and
  26.0.0 describes complete Ada 2012 syntax support and Ada 2022
  support as work in progress. Version 26.0.0 resolves through
  `libgpr2` to GNAT below 16, while version 25.0.0 has not yet been
  built in this project. The dependency closure includes GNAT
  Components Collection crates licensed
  `GPL-3.0-or-later WITH GCC-exception-3.1`; licensing and
  redistribution of the complete closure need review.

### Dmitry Kazakov's Ada Syntax Analyzer

- Benefits: version 1.0 is advertised as a full Ada 2022 syntax
  analyzer; it builds a syntax tree and a cross-reference of defining
  identifiers. Its documented API is Ada.
- Costs and risks: the documented cross-reference search returns
  visible candidate declarations while ignoring `use` clauses; the
  documentation does not establish full semantic resolution of type
  references. The advertised license is GPL-2.0-or-later with a
  special linking exception. The distribution includes source from
  Simple Components, so the exact licenses and dependencies of the
  parser sources used by hac-bindgen need checking. The prototype
  compiles with GNAT 16, but emits upstream warnings, including
  unchecked-conversion size mismatches; these need assessment before
  relying on the library.

## Evidence

- The tagged Libadalang 25.0.0 and 26.0.0 README files describe full
  Ada 2012 syntax support, with Ada 2022 constructs still in progress.
  The current development-branch README reports full Ada 2022 syntax
  parsing. The library explicitly says it does not provide full Ada
  legality checking, so GNAT remains the legality authority as
  required by S012.
- Alire lists Libadalang 26.0.0 as `Apache-2.0 WITH LLVM-exception`.
  Its `libgpr2` 26.0.0 dependency requires `gnat < 16`; Alire's
  resolved candidate selects GNAT 15.3.1.
- Alire lists Libadalang 25.0.0 with the same project license. Its
  dependency solution selects GNAT 16.1.0, matching the current
  project minimum, but has not yet been built against hac_bindgen.
- The Alire metadata for GNAT Components Collection dependencies lists
  `GPL-3.0-or-later WITH GCC-exception-3.1`. This is an initial
  inventory, not a complete legal review of all transitive components
  and distribution obligations.
- Dmitry Kazakov's [Ada Syntax Analyzer documentation](https://www.dmitry-kazakov.de/ada/ada_syntax_analyzer.htm)
  documents syntax-tree construction and a cross-reference of defining
  identifiers. Its license notice is GPL-2.0-or-later with a special
  linking exception. The version 1.0 archive was retrieved and its
  SHA-256 matched the hash published by SourceForge. Its library and an
  isolated API probe both compiled with GNAT 16.
- The probe parsed a package containing a subtype, enumeration type,
  procedure, function, constant, and private object. The syntax tree
  preserved declaration order, profiles, parameter modes, and line and
  column locations. Cross-reference contexts exposed five public
  declarations separately from the private object, and
  `Get_Item`/`Get_Items_Number` traversed those declarations by node
  class.
- `Find` returned one visible candidate for the fixture's `Small`
  subtype use and none for predefined `Integer` in that isolated
  source. This demonstrates candidate lookup, not complete type
  resolution or a semantic environment for predefined types.

## Provisional direction

Do not implement a home-grown Ada parser. The structural prototype for
Dmitry Kazakov's Ada Syntax Analyzer 1.0 succeeded; compare it with
Libadalang 25.0.0 on the same focused fixture before selecting a backend.
Neither backend is selected yet.

## Rationale

The alternatives are real Ada analysis libraries with different
strengths: Libadalang exposes semantic resolution and an Alire-managed
dependency, while Dmitry Kazakov's analyzer advertises Ada 2022 syntax
coverage. The latter's documented cross-reference and type-resolution
capabilities need checking against the model requirements rather than
assuming syntax coverage provides semantic resolution.

## Consequences

- Keep either backend out of the production manifest until its focused
  prototype builds with the project's GNAT 16 toolchain.
- Do not lower the project's GNAT minimum merely to use Libadalang 26.
- Complete license and redistribution review for the selected
  backend's actual source and dependency closure before finalizing the
  decision or preparing a release.
- GNAT remains the legality authority; Libadalang diagnostics and
  either analyzer's syntax/semantic facilities are analysis inputs,
  not a replacement for the host compiler.

## Template for a new discussion

Copy this block for each new discussion, as a `###` section.

### <title>

Status: Discussing
Date: YYYY-MM-DD
Related: <proposal, concern, issue, or feature>

## Context

<Forces and constraints that make a decision necessary.>

## Options considered

### Option A

- Benefits: ...
- Costs and risks: ...

### Option B

- Benefits: ...
- Costs and risks: ...

## Decision

<Leave open while Discussing.>

## Rationale

<Why this option was selected.>

## Consequences

- ...
