# hac_bindgen specifications <!-- omit from toc -->

This document holds the non-functional specifications of hac-bindgen,
the specification method that structures them, and the index of the
feature pages. The spirit of the tool is stated in
[`manifesto.md`](manifesto.md); the testable behavior lives in the
feature pages.

## Contents <!-- omit from toc -->

- [1. Specification method](#1-specification-method)
- [2. Non-functional specifications](#2-non-functional-specifications)
  - [[S001] Determinism](#s001-determinism)
  - [[S002] Generated-file identification](#s002-generated-file-identification)
  - [[S003] No silent conversion](#s003-no-silent-conversion)
  - [[S004] Generated code quality](#s004-generated-code-quality)
  - [[S005] Input is plain legal Ada](#s005-input-is-plain-legal-ada)
  - [[S006] Traversal contract](#s006-traversal-contract)
  - [[S007] Failure classes](#s007-failure-classes)
  - [[S008] Test philosophy](#s008-test-philosophy)
  - [[S009] No handwritten glue](#s009-no-handwritten-glue)
  - [[S010] Command-line interface](#s010-command-line-interface)
  - [[S011] Restriction is a feature](#s011-restriction-is-a-feature)
  - [[S012] GNAT remains the legality authority](#s012-gnat-remains-the-legality-authority)
- [3. Feature index](#3-feature-index)
- [4. Cross-reference table](#4-cross-reference-table)
- [5. Terminology](#5-terminology)
- [6. Scope and non-goals](#6-scope-and-non-goals)
- [7. Acceptance criteria](#7-acceptance-criteria)
- [8. Failure criteria](#8-failure-criteria)
- [9. Design principles for future extensions](#9-design-principles-for-future-extensions)
- [10. References](#10-references)

## 1. Specification method

The specifications are organised in two places:

- **`features/`** — every *testable* functionality of hac-bindgen, one
  Markdown page per feature group, holding the bbt executable
  scenarios. The feature pages are the executable documentation.
- **`proposed/`** — feature pages that are specified but not yet
  executable: their scenarios do not run yet, so they stay out of the
  bbt run.
- **this document** — every *non-functional* specification: the rules
  that apply across features (determinism, generated-code marking,
  conversion safety, testing philosophy, error model), plus an index
  of the features.

Rules of the method:

- The feature pages own every detail. The index below may summarise a
  feature, but never repeats what the page states: one durable source
  per fact.
- A feature page stays in `proposed/` while it is only specified, and
  moves to `features/` once its bbt scenarios run green. Feature pages
  carry no status line: the distinction is made by the location and by
  the index in section 3.
- Features are numbered by a stable scheme:

  | Prefix | Meaning |
  |---|---|
  | `Annn` | features about the Ada language traits that hac-bindgen interfaces |
  | `Bnnn` | features about the language traits hac-bindgen cannot bind, and their warnings |
  | `Cnnn` | error cases: bad usage, bad input, failures of the tool itself |

  The next free number of each series is allocated in the index below.
- Scenario and requirement identifiers are stable: a number never
  changes meaning, a removed scenario never gets reused, and pages keep
  their number for life.
- The bbt scenarios, the source code and its comments may reference a
  spec identifier (e.g. `[S003]`, `[A002-02]`).
- A cross-reference table (section 4) is maintained to show what a
  requirement impacts: which features test it, and which source units
  implement it.
- This method applies to every project using the reference template
  (see `documentation_structure.md` in
  [ada-project-template](https://github.com/LionelDraghi/ada-project-template)).

## 2. Non-functional specifications

Each specification carries a stable identifier `Snnn`.

### [S001] Determinism

Generation is deterministic: the same input files and the same
generator version produce byte-identical output files. Generated files
never contain timestamps, absolute paths, host or user names, random
identifiers, or any other machine-specific data.

### [S002] Generated-file identification

Every generated textual artefact identifies the generator and its
version in a header comment; the same version appears in every
generated artefact of one run and matches `hac-bindgen --version`.

### [S003] No silent conversion

A binding never silently narrows a numeric value, truncates a string,
reinterprets an integer as an application object, ignores an invalid
enumeration position, converts a negative value to an unsigned type,
suppresses an exception, or replaces an invalid result with a default
value. A conversion that cannot be performed safely is warned out at
generation time ([B-series](features/#warnings)) or reports a defined
boundary error at run time ([C-series](features/#error-cases)).

### [S004] Generated code quality

Generated code is formatted as ordinary Ada source, understandable
without knowing the generator internals, compilable by the normal GNAT
and HAC processes, and suitable for review. Generated source units are
marked as generated in their header ([S002]) and are never hand-edited.

### [S005] Input is plain legal Ada

The input of hac-bindgen is ordinary legal Ada, compilable by the host
compiler without hac-bindgen. No invented aspects, no
hac-bindgen-specific syntax, no implementation-specific source
transformations. A package fed to hac-bindgen must build before and
after binding generation.

### [S006] Traversal contract

hac-bindgen traverses the public API of the supplied package
specification(s) and classifies each exported declaration:

- bindable: the declaration enters the generated binding;
- not bindable: the declaration triggers a warning carrying a stable
  diagnostic identifier, the source location, and the reason.

A non-bindable declaration never blocks the generation of the rest of
the package, and is never silently dropped.

### [S007] Failure classes

Three failure classes remain distinct:

1. **Generation diagnostics** — the API shape is not bindable:
   warnings ([B-series] and [C-series]) emitted by the tool at
   generation time.
2. **Boundary errors** — the API shape is bindable, but the HAC
   program supplies an invalid runtime value (out-of-range integer,
   invalid enumeration position, wrong arity): reported by the
   generated callback at run time.
3. **Application errors** — the façade or the application raises:
   translated through HAC's error mechanism by the generated adapter,
   never swallowed.

### [S008] Test philosophy

The bbt scenarios test the complete production path: Ada API files as
Given, hac-bindgen invocations as When, real compiler calls (GNAT,
real HAC compiler and VM) and output comparison as Then. The script
produces the actual result; the bbt scenario owns the expected result.
A mock of HAC, of the generated code, or of the native application is
never evidence: no mocked-HAC and no generated-source-only reference
tests count as end-to-end validation.

### [S009] No handwritten glue

Adding one bindable façade operation requires no handwritten
HAC-specific adapter code in the application: everything
operation-specific is generated. Only the generic HAC embedding
bootstrapping of the witness application may be handwritten.

### [S010] Command-line interface

`hac-bindgen` is a command-line tool with the subcommands `generate`
and `check`, plus `--version`. The reference surface is specified in
[features/A001_cli.md](features/A001_cli.md); this document only fixes
that the CLI exists as the sole entry point of the tool and that every
command reports a defined exit status.

### [S011] Restriction is a feature

The binding profile is deliberately narrow. A restricted boundary
provides deterministic code generation, readable generated code, clear
diagnostics, stable scripting APIs and a small trusted implementation.
The complexity of an application stays behind its scripting façade.
The restriction shapes what hac-bindgen binds — never what it accepts
as input ([S006]).

### [S012] GNAT remains the legality authority

Neither the analysis backend nor hac-bindgen replaces compilation by
GNAT. An exposed package must compile as ordinary Ada code, before and
after binding generation. Parser or traversal acceptance alone is
never proof that a source unit is legal Ada.

## 3. Feature index

A feature page lives in [`features/`](features/) once its bbt scenarios
run green; it stays in [`proposed/`](proposed/) while it is only
specified. Feature pages carry no status line.

Executable features (`features/`):

| ID | Feature | Page | Status |
|---|---|---|---|
| A001 | Command-line interface | [A001_cli.md](features/A001_cli.md) | partially implemented |
| A002 | Facade generation: scalar profile | [A002_facade_generation.md](features/A002_facade_generation.md) | implemented |
| A003 | Analysis backend interchange dump | [A003_interchange_dump.md](features/A003_interchange_dump.md) | implemented |
| A005 | Rich enumerations at the boundary | [A005_enumerations.md](features/A005_enumerations.md) | implemented |
| B001 | Non-bindable constructs: warnings | [B001_non_bindable_constructs.md](features/B001_non_bindable_constructs.md) | partially implemented |
| C001 | Usage and input errors | [C001_usage_errors.md](features/C001_usage_errors.md) | implemented |

Proposed features ([`proposed/`](proposed/), specified, not executable):

| ID | Feature | Page |
|---|---|---|
| A004 | Handle profile: opaque objects across the boundary | [A004_handles.md](proposed/A004_handles.md) |
| C002 | Runtime boundary errors | [C002_boundary_errors.md](proposed/C002_boundary_errors.md) |

Next free identifiers: `A006`, `B002`, `C003`.

## 4. Cross-reference table

Generated view of the impact of each non-functional specification.
Updated by hand while the tool has no report generator; regenerated
later by `make doc` if it earns its cost.

| Specification | Tested by | Implemented in |
|---|---|---|
| [S001] determinism | A002 (regeneration scenario) | src/hac_bindgen-generation\* |
| [S002] generated-file identification | A002, B001 | src/hac_bindgen-generation\* |
| [S003] no silent conversion | A002, C002 | src/hac_bindgen-generation\*, generated adapter |
| [S004] generated code quality | A002 | src/hac_bindgen-generation\* |
| [S005] input is plain legal Ada | A002, B001 | (input contract) |
| [S006] traversal contract | A002, B001 | src/hac_bindgen-analysis\*, src/hac_bindgen-traversal\* |
| [S007] failure classes | B001, C001, C002 | src/hac_bindgen-cli\*, generated adapter |
| [S008] test philosophy | all pages | tests/ |
| [S009] no handwritten glue | A002 | generated adapter |
| [S010] CLI | A001, C001 | src/hac_bindgen-cli\* |
| [S011] restriction is a feature | A002, B001 | binding profile |
| [S012] GNAT remains the legality authority | A002, C001 | tests/ |

## 5. Terminology

The vocabulary below is used across the manifesto, the specifications
and the feature pages.

| Term | Meaning |
|---|---|
| Native package | An Ada package compiled by the host compiler and linked into the application. |
| Rich application API | The native API of the application; may use private types, generics, tagged types, contracts — full Ada. |
| Scripting façade | A native Ada package deliberately designed to be exported to HAC. Optional: hac-bindgen also works directly on the rich API. |
| Binding profile | The subset of Ada declarations and types hac-bindgen binds. |
| Traversal | The pass that classifies every public declaration of the supplied package(s): bindable or warned ([S006]). |
| Native adapter | Generated native Ada code called from HAC and delegating to the bound API. |
| HAC declaration | Generated source declaring the bound operations to HAC programs (`with Import => True`). |
| Binding model | The parser-independent intermediate representation used by validation and code generation. |
| Binding manifest | A generated machine-readable description of the exported API and its mappings (gadget). |
| Handle | An application-defined scalar identifier representing a native object. |
| Witness application | A small real Ada application that embeds HAC, registers the generated bindings, and is compiled by GNAT as part of the end-to-end tests. |

## 6. Scope and non-goals

The goal: bind the public operations of the supplied package
specification(s) to HAC — generating the scripting façade and its glue —
and warn on everything that cannot be bound ([S006]).

The initial experiment will not:

- bind non-public declarations (bodies, children, private parts);
- infer application object ownership or lifetime;
- automatically flatten arbitrary private types;
- instantiate generic packages;
- expose tagged dispatching;
- reproduce Ada overloading inside HAC;
- map arbitrary records, discriminated records, arrays or access types;
- accept callbacks supplied by HAC programs;
- provide binary plug-in compatibility or dynamic library loading;
- implement a general-purpose Ada FFI;
- replace GNAT, or a general semantic analysis framework;
- modify HAC language semantics;
- depend on application object layouts;
- promise compatibility with Ada constructs unsupported by HAC.

Restriction remains a feature ([S011]): a narrow binding profile keeps
code generation deterministic, diagnostics clear, generated code
readable and the trusted implementation small.
## 7. Acceptance criteria

The experiment is technically successful when all the following hold.
Each criterion points at the specification or feature that demonstrates
it.

1. A developer can expose a package — rich or curated — to hac-bindgen
   as ordinary legal Ada ([S005], [A002]).
2. The exposed package does not import or call `HAC_Sys.Interfacing`.
3. One `hac-bindgen` command generates all per-operation HAC glue
   ([S009], [A002-09]).
4. Every generated file identifies the hac-bindgen version ([S002]).
5. The generated native code compiles with GNAT ([S012]).
6. The generated HAC declarations compile with the real HAC compiler.
7. A GNAT-compiled witness application embeds the real HAC runtime
   ([S008]).
8. A real HAC script calls the bound operations end to end ([A002-01]
   and follow-ups).
9. Scalar parameters and results survive round trips with documented
   conversions ([A002-02], [A002-03], [S003]).
10. Distinct handle types can represent native objects without
    transferring their representation into HAC (M6, future `Annn`
    page).
11. Invalid handles are detected by the application boundary (M6).
12. Non-bindable declarations produce precise warnings, with stable
    identifiers and source locations ([S006], [B001]).
13. Generated code is deterministic and understandable ([S001], [S004]).
14. Adding one bindable façade function requires no handwritten
    HAC-specific adapter code ([S009], [A002-09]).
15. bbt executes the complete chain and compares the actual result
    against the expected result stored in the scenario ([S008]).
16. The implementation remains independent of any example or
    motivating application.

## 8. Failure criteria

The experiment is stopped or redesigned if any of these proves true:

- HAC callbacks cannot express ordinary functions and procedures
  without handwritten per-operation code;
- external declarations cannot be generated or associated reliably
  with registered callbacks;
- simple scalar conversions require application-specific changes to
  the generator;
- generated adapters depend on application object layouts;
- the analysis integration requires implementing a general Ada
  semantic analyser;
- non-bindable declarations cannot be diagnosed reliably;
- generated code is harder to maintain than handwritten glue;
- adding a normal façade operation routinely requires changes to the
  generator;
- the analysis backend licensing prevents practical distribution;
- real end-to-end tests cannot be automated with the actual HAC
  runtime;
- generated source cannot be made deterministic.

A negative result is useful: it establishes the actual boundary of HAC
interfacing.

## 9. Design principles for future extensions

Any extension of the binding profile must satisfy all these rules:

1. motivated by a demonstrated scripting façade;
2. deterministic mapping;
3. generated code stays readable;
4. conversion rules explicit and testable;
5. failure behaviour defined;
6. no application-semantic inference;
7. analyser independence preserved;
8. diagnostics not weakened;
9. positive, negative and real end-to-end bbt tests included;
10. not accepted merely because the analyser parses it, or because
    GNAT compiles it — only once HAC executes it through the
    generated binding.

## 10. References

- [HAC Ada Compiler repository](https://github.com/zertovitch/hac)
- `HAC_Sys.Interfacing` and the `demo/data_exchange*` examples in the
  [HAC 0.45 sources](https://github.com/zertovitch/hac/tree/v0.45) —
  the reference for M2
- [Dmitry Kazakov's Simple Components](https://dmitry-kazakov.de/ada/components.htm)
  and the [Ada Syntax Analyzer](https://sourceforge.net/projects/ada-syntax-analyzer/)
- [Libadalang](https://github.com/AdaCore/libadalang) and its
  [user manual](https://docs.adacore.com/live/wave/libadalang/html/libadalang_ug/index.html)
- [bbt](https://github.com/LionelDraghi/bbt) — the executable
  documentation tool
