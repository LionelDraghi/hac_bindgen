# Design discussions <!-- omit from toc -->

This document records structural choices, alternatives, rationale, and
status. It does not duplicate behavioral specifications. An open
decision may be indexed as a concern when it blocks work or creates
material risk.

| Decision | Status | Date |
|---|---|---|
| Parser-independent binding model contract | Accepted | 2026-10-29 |
| Analysis backend: Libadalang vs Dmitry Kazakov's Ada Syntax Analyzer | Accepted (Libadalang) | 2026-10-29 |
| Interchange format between backend and main crate | Accepted (house line-oriented text; JSON deferred) | 2026-10-29 |
| HAC declaration mechanism: `with Import => True` placement (nested vs package spec) | Discussing | 2026-10-29 |
| Boolean mapping route: generic enum vs Integer | Discussing | 2026-10-29 |
| Manifest design (generated artefacts policy): check-in policy, generation during builds, source hashes, version coupling, JSON format | Discussing | 2026-10-29 |

Statuses: Discussing | Accepted | Rejected | Superseded.

## Contents <!-- omit from toc -->

- [Parser-independent binding model contract](#parser-independent-binding-model-contract)
  - [Classification embedded in each declaration](#classification-embedded-in-each-declaration)
  - [Separate analysis result linked by declaration identity](#separate-analysis-result-linked-by-declaration-identity)
- [Analysis backend evaluation](#analysis-backend-evaluation)
  - [Libadalang](#libadalang)
  - [Dmitry Kazakov's Ada Syntax Analyzer](#dmitry-kazakovs-ada-syntax-analyzer)
- [Backend license and redistribution review](#backend-license-and-redistribution-review)
- [Interchange format between backend and main crate](#interchange-format-between-backend-and-main-crate)
  - [JSON](#json)
  - [TOML](#toml)
  - [House line-oriented text](#house-line-oriented-text)
- [Template for a new discussion](#template-for-a-new-discussion)

### Parser-independent binding model contract

Status: Accepted
Date: 2026-10-29
Related: implemented in `Hac_Bindgen.Model` and
`Hac_Bindgen.Dump_Reader`; see also the
[interchange format discussion](#interchange-format-between-backend-and-main-crate)

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
- Backend selection is settled (Libadalang, 2026-10-29); the license
  and redistribution review of its dependency closure remains open and
  is tracked separately.

### Analysis backend evaluation

Status: Accepted (Libadalang)
Date: 2026-10-29
Related: M3; [backend licensing concern](concerns.md)

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
- Both candidates were then compared on the same focused fixture,
  `tools/libadalang_trial/probe_fixture.ads`, by two probe drivers that
  dump every public and private declaration with kind, name, source
  location, subprogram profiles (parameter names, modes, types), enum
  literals, subtype base type and range, and object/constant values
  (dumps: `tools/libadalang_trial/probe_fixture_analysis.txt` and
  `tools/Kazakov_Analyzer_trial/probe_fixture_analysis.txt`).
- On that fixture both extract the same structural coverage: public
  and private parts separated, declaration order preserved, profiles
  with parameter names, modes, and types, enumeration literals, and
  line:column locations.
- Only Libadalang provides semantic resolution: `P_Referenced_Decl`
  resolves `Small` to its declaring subtype and `Integer` to the
  predefined `__standard` unit, `P_Base_Subtype` gives the ultimate
  base type of a subtype, and the `Expr_Eval` evaluator returns the
  statically evaluated range bounds (`1`, `10`) and constant value
  (`Value = 2`) with RM semantics.
- Kazakov's analyzer resolves names only within the parsed sources:
  `Integer`, `Boolean`, and `Interfaces` come back unresolved, subtype
  range bounds are token text (`"1..10"`) rather than evaluated bounds,
  and there is no overload resolution, type propagation, or
  representation information.
- Driver friction on the same dump: the Libadalang probe is 281 lines
  against a homogeneous node API (`Ada_Node` + `Kind`, generic
  iteration, `As_*` conversions); the Kazakov probe is 402 lines
  against a per-class typed node hierarchy (explicit `Get_Class`
  dispatch, downcasts per class, explicit arena/stack storage).
- The Libadalang 26.0.0 probe builds and runs standalone under GNAT
  FSF 15.2.0 via Alire (isolated trial crate, 16 s build); the Kazakov
  probe builds under GNAT 16.1. Both run to completion on the fixture.
- Integration attempt of Libadalang 25.0.0 into the main crate with
  GNAT 16.1.0: the dependency solution resolves (libadalang, GNATCOLL,
  langkit_support, xmlada, vss, prettier_ada, libgpr/libgpr2, adasat,
  all 25.0.0) but the build fails — `libgpr2` 25.0.0 sources do not
  compile under GNAT 16.1.0 (legality errors such as
  `gpr2-project-import-set.ads:95:09: component "Ref" of type
  "Constant_Reference_Type" has limited type`), and `libgpr2` 26.0.0
  declares `gnat<16`. Under GNAT 16, no indexed Libadalang release
  builds today; `gnat_native` 16.2.0-pre0 exists in the index but is
  untested. The main crate was restored to a green build after the
  attempt.

## Decision

Select Libadalang as analysis backend #1, and use Dmitry Kazakov's Ada
Syntax Analyzer only as comparison evidence. The binding model
requires resolved type references, subtype chains, and statically
evaluated constraints; Libadalang provides them natively while
Kazakov's analyzer stops at name lookup inside the parsed sources.

Integration follows the isolation architecture: the backend lives in
its own Alire crate (`tools/libadalang_backend`), pinned to the GNAT
15.x toolchain that Libadalang supports, and communicates with the
main generator — which stays on GNAT 16 — through a stable textual
model dump produced by a dedicated executable. The main crate never
links Libadalang; the interchange format is the contract between the
two crates.

## Rationale

The model contract stores resolution state and subtype chains per
declaration. With Libadalang these come directly from the library
(`P_Referenced_Decl`, `P_Base_Subtype`, `Expr_Eval`); with Kazakov's
analyzer the backend would have to rebuild a semantic layer — parse
predefined-unit specifications, map names to a table of known types,
and evaluate static expressions itself — which is precisely the work
the generator exists to avoid. The two probes produced equivalent
structural dumps, so the decision rests on semantic capability, Alire
integration, and lower driver friction (281 vs 402 lines for the same
dump), not on syntax coverage.

## Consequences

- Implement backend #1 (package specification to `Hac_Bindgen.Model`)
  with Libadalang; `tools/Kazakov_Analyzer_trial` is kept as decision
  evidence and can be dropped once backend #1 lands.
- Backend isolation resolves the version conflict: the backend crate
  is pinned to GNAT 15.x and Libadalang 26.0.0, the main crate keeps
  its GNAT 16 minimum, and the only coupling is the dump format.
- Do not link Libadalang into the main crate until upstream `libgpr2`
  supports GNAT 16 (contributing the port there is the medium-term
  fix; `gnat_native` 16.2.0-pre0 remains untested).
- The license and redistribution review of the Libadalang dependency
  closure is its own decision (2026-10-31): no blocking
  incompatibility, see the license review section below.
- Probe-level coverage does not establish full Ada 2022 syntax or
  inter-unit resolution (`with Interfaces` was not resolved in the
  trial); extend the probe with these cases before relying on them in
  backend #1.
- GNAT remains the legality authority; Libadalang diagnostics are
  analysis inputs, not a replacement for the host compiler.

### Interchange format between backend and main crate

Status: Accepted (house format type; grammar to be specified)
Date: 2026-10-29
Related: [analysis backend evaluation](#analysis-backend-evaluation);
[interchange format proposal](../features/A003_interchange_dump.md);
[interchange format concern](concerns.md)

## Context

With the backend isolated in its own crate, the dump it writes is the
only coupling with the main generator. Both producers and consumers
are programs under this repository's control; the dump must also feed
bbt golden files and stay diffable across machines.

## Options considered

### JSON

- Benefits: interoperability with external tools (IDEs, SARIF, the
  manifest gadget) and off-the-shelf consumers.
- Costs and risks: needs a parser or a dependency on the main crate
  side; punctuation noise makes golden files harder to read; no
  external consumer exists today.

### TOML

- Benefits: human-friendly configuration syntax.
- Costs and risks: designed for hand-written configuration, not
  program output — serializing nested structures (profiles, parameters,
  resolved types) is verbose, and no pure-Ada TOML parser exists under
  GNAT 16; writing one is disproportionate.

### House line-oriented text

- Benefits: trivial to emit and to parse (both sides are ours),
  readable and diffable golden files for bbt, grammar specifiable in a
  page, zero dependencies; in line with the gcc-diagnostics style
  already used for warnings.
- Costs and risks: no external interoperability; the grammar must be
  frozen and versioned once consumers appear.

## Decision

Use a house line-oriented text format for the backend-to-main-crate
dump. Keep it deterministic and machine-parsable: one declaration per
line with tagged fields and canonical locations. Defer JSON to the
manifest design (it remains a possible *view* of the same model if the
manifest gadget becomes real); reject TOML for program output. The
exact grammar is specified in
[the interchange format proposal](../features/A003_interchange_dump.md).

## Rationale

The only current consumer is hac_bindgen itself, plus bbt scenarios.
A house format optimizes both without dependencies, while JSON's
single benefit (external interoperability) belongs to the manifest
discussion, not to this internal contract.

## Consequences

- The backend executable and the main crate reader implement the same
  grammar; format 1 is frozen since the reader
  (`Hac_Bindgen.Dump_Reader`) landed (2026-10-30), and any change now
  requires a format bump.
- The main crate runs the backend executable through
  `GNAT.Expect.Get_Command_Output`. The objections that led bbt to
  reject `GNAT.Expect` (sliding buffer, TTY pollution, exit status of
  an already terminated child — see the bbt design discussion D1) were
  re-checked against this narrower use and do not apply: the capture
  drains to end of stream with an unbounded buffer, no TTY is
  involved, and the exit status of a child that terminated normally is
  reported correctly (re-verified on GNAT 16.1, 2026-10-30).
- Format-1 facts that the model does not carry yet (enum literals,
  static constraints and values, unhandled kind names) are checked for
  conformance by the reader and dropped; tracked as a concern.

### Backend license and redistribution review

Status: Accepted (no blocking incompatibility)
Date: 2026-10-31
Related: M3; [backend licensing concern](concerns.md), now closed

## Context

The backend binary links the Libadalang dependency closure; the main
crate never does (separate process, text dump only). The initial
inventory (2026-10-29) flagged the GNATCOLL crates as
`GPL-3.0-or-later WITH GCC-exception-3.1` and left the redistribution
review open.

## Evidence

Licenses verified against the actual sources of the crates in the
build tree (not only the Alire manifests), on 2026-10-31:

| Crate | License | Verified |
|---|---|---|
| libadalang, langkit_support | Apache-2.0 | `SPDX-License-Identifier: Apache-2.0` in the source headers |
| gnatcoll, gnatcoll_gmp, gnatcoll_iconv, gnatcoll_projects | GPL-3.0-or-later WITH GCC-exception-3.1 | `COPYING3` + `COPYING.RUNTIME` shipped |
| xmlada, libadalang_tools | GPL-3.0-or-later WITH GCC-exception-3.1 | same |
| adasat, libgpr2 | Apache-2.0 WITH LLVM-exception | Alire manifest |

What `hac_bindgen_backend` actually links: `GNATCOLL.GMP.Integers`
(hence gnatcoll_gmp and gnatcoll core) and Libadalang with its
Langkit support — the analysis core is Apache-2.0. xmlada,
gnatcoll_projects and libadalang_tools are in the build closure but
nothing of them is referenced, so nothing is linked into the binary.

## Decision

No blocking incompatibility:

1. The GCC Runtime Library Exception 3.1 exists exactly for this: a
   compiler-generated program containing portions of such a library is
   conveyed under the terms of the distributor's choice, provided the
   library's own sources stay available under GPL-3 - satisfied by
   construction for an Alire crate (the dependency sources come from
   the index).
2. The format-1 dump describes the user's source (names, locations,
   types): it is data derived from the user's input, not a derivative
   work of Libadalang. With the process separation, the Apache-2.0
   main crate is clean beyond doubt.
3. GMP itself (the C library bound by gnatcoll_gmp) is LGPL-3:
   statically linked by default. The project distributes sources only
   (Alire) - each user's build links their own GMP - so no
   redistribution obligation applies to the project. This becomes a
   constraint only if prebuilt binaries are ever distributed: then the
   LGPL section 4 means (relink capability) must be provided.

## Consequences

- The backend and the main crate may be distributed as Apache-2.0.
- If prebuilt binaries are ever shipped, revisit the LGPL-3 clause for
  GMP (provide relink means) and ship the GPL-covered library sources
  or their fetch path.
- `libadalang_tools` stays a backend dependency for `make metrics`
  only; nothing of it is linked into the backend binary.

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
