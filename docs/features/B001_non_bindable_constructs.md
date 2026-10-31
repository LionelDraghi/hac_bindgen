# B001 — Non-bindable constructs: warnings <!-- omit from toc -->

hac-bindgen traverses the supplied API and binds what it can; what it
cannot bind triggers a warning, never a package rejection, and never a
silent drop ([S006]). This page owns the catalogue of non-bindable
constructs, the warning format, and the traversal summary. The
generated-file side (what `generate` writes for the bound part) is
[A002](A002_facade_generation.md); the runtime failures of bound
operations are [C002](C002_boundary_errors.md).

## Contents <!-- omit from toc -->

- [Warning format](#warning-format)
- [The catalogue](#the-catalogue)
- [Classification rules for the first profile](#classification-rules-for-the-first-profile)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: an overloading is warned out, the rest is classified](#scenario-an-overloading-is-warned-out-the-rest-is-classified)
  - [Scenario: every warning is actionable](#scenario-every-warning-is-actionable)
  - [Scenario: pointer-ish declarations are all warned out](#scenario-pointer-ish-declarations-are-all-warned-out)
  - [Scenario: composite and tagged boundary declarations are warned out](#scenario-composite-and-tagged-boundary-declarations-are-warned-out)
  - [Scenario: nothing is silently dropped](#scenario-nothing-is-silently-dropped)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)

## Warning format

Warnings are gcc-style, one line per non-bindable declaration:

```text
source.ads:LINE:COL: warning HACBxxxx: <construct> is not bound: <reason>
```

They go to the standard output, next to the summary: classifying the
API is the tool's normal work, not a failure — the standard error is
reserved for the cases where bindgen itself is in difficulty
(analysis failure, crash, cannot finish the generation; [C001]). One
summary line per analysed package:

```text
Geometry: 7 operations bound, 2 not bound (see warnings)
```

Warnings are diagnostics, not errors: the exit status stays `0` when
the analysis itself succeeded, even with warnings. They only report
what the generated binding will not cover ([S007], class 1).

## The catalogue

Each row is specified when the traversal reaches the construct; the
scenarios below exercise the first entries. The identifier is the
stable key: it never changes meaning.

| Identifier | Construct | Why it is not bound (first reason) |
|---|---|---|
| HACB0001 | overloaded public name | HAC callbacks are keyed by a single name |
| HACB0002 | operator symbol (`"+"`, ...) | not a valid callback name |
| HACB0003 | access type or access parameter | no pointer representation across the VM boundary |
| HACB0004 | private, limited, tagged, interface or class-wide type as boundary value | the tool does not own object representation |
| HACB0005 | record, discriminated record, anonymous array or record as boundary value | composite mapping deferred; explicit profile first |
| HACB0006 | task or protected object | no VM representation |
| HACB0007 | generic package or subprogram | instantiate natively, bind the instance |
| HACB0008 | `out` / `in out` parameter | deferred until the copy-back semantics is demonstrated |
| HACB0009 | default parameter expression | HAC caller supplies every argument |
| HACB0010 | fixed-point or modular type | conversion semantics to be demonstrated first |
| HACB0011 | exception declaration | Ada exception identity does not cross the boundary |
| HACB0012 | renamings | declare a regular wrapper instead |
| HACB0013 | unresolved external type | the analyser cannot resolve the type of the declaration |
| HACB0014 | `System.Address` or native pointer representation | unchecked address conversions have no defined VM semantics |
| HACB0015 | controlled type as boundary value | finalization has no counterpart in the VM |
| HACB0016 | binding requiring semantic inference (ownership, lifetime, aliasing, thread safety, units, free-on-return) | those decisions belong to the application, not to the generator |
| HACB0017 | enumeration with character literals | HAC only accepts identifier literals |

## Classification rules for the first profile

- Only subprogram declarations count as operations in the summary;
  type, object and exception declarations appear only through their
  warnings.
- Object declarations (variables and constants) are never bound by
  the first profile — the M2 evidence demonstrates no variable or
  constant mechanism across the boundary — so they always warn
  `HACB0016`, whatever their type.
- Each non-bindable construct is reported: declaration-level issues
  (overload, operator symbol) warn at the declaration location; each
  non-bindable parameter or result warns at its own location. A
  declaration that received at least one warning counts as not bound.
- The overload rule: within one package, the first declaration of a
  name is bound, subsequent declarations of the same name are warned
  `HACB0001`.
- Inherently non-representable declarations warn by themselves, where
  they stand: access types (`HACB0003`), exception declarations
  (`HACB0011`), generic units (`HACB0007`), task and protected
  declarations (`HACB0006`), enumerations with character literals
  (`HACB0017`, [A005](A005_enumerations.md)). Representation-choice
  types (record, tagged, private) are only warned when they appear as
  a boundary value: they may become handles in a later profile.
- A type is classified through the root of its subtype chain:
  integer, floating-point, boolean and enumeration roots are bindable,
  except an enumeration root with character literals, which warns
  `HACB0017` ([A005](A005_enumerations.md));
  access roots warn `HACB0003`; array, record and string roots warn
  `HACB0005`; tagged and private roots warn `HACB0004`; fixed-point
  and modular roots warn `HACB0010`; task and protected roots warn
  `HACB0006`; a type the analyser cannot resolve to a known category
  warns `HACB0013`. `System.Address` is recognized by name and warns
  `HACB0014`.
- A declaration the analysis backend could not classify (an
  `unhandled` dump entry outside the cases above) warns `HACB0016`:
  nothing leaves the traversal unaccounted for.
- The summary spells `1 operation` in the singular, `N operations`
  otherwise; the `(see warnings)` suffix appears whenever at least one
  warning was emitted for the package, even when the unbound part is
  not made of operations.

## Executable scenarios

All scenarios run `check`; `generate` shares the same classification
and adds file writing in A002. The scenarios run from `tests/`, like
the A001 ones. The scenario identifiers are the stable keys used by
the roadmap and the specifications:

| Scenario | Behavior |
|---|---|
| B001-01 | an overloading is warned out, the rest is classified |
| B001-04 | every warning is actionable |
| B001-05 | pointer-ish declarations are all warned out |
| B001-06 | composite and tagged boundary declarations are warned out |
| B001-07 | nothing is silently dropped |
| B001-02 | the generated binding covers the bindable part only (the [A002-05] scenario of [A002](A002_facade_generation.md)) |
| B001-03 | `check` reports the same classification as `generate` (pinned by the identical warning and summary formats of the B001-01, B001-05 and [A002-05] scenarios) |

B001-02 and B001-03 have no scenario of their own: one authoritative
description per behavior — B001-02 is exactly the A002-05 scenario (a
mixed package generates only the bound subprograms, [S006], [S009]),
and B001-03 follows from the single-traversal rule ([S006]): `check`
and `generate` run the same classification path, and the scenarios
pinning each side show the same warning and summary formats.

### Scenario: an overloading is warned out, the rest is classified

- Given the new file `classify_probe.ads` containing
  ```ada
  package Classify_Probe is
     procedure Create (X : in Integer);
     procedure Create (X : in Float);
     procedure Ping (X : in Integer);
  end Classify_Probe;
  ```
- When I run `../bin/hac-bindgen check classify_probe.ads`
- Then there is no error
- And there is no error output
- And I get
  ```text
  classify_probe.ads:3:16: warning HACB0001: procedure Create is not bound: the name Create is already bound: HAC callbacks are keyed by a single name
  Classify_Probe: 2 operations bound, 1 not bound (see warnings)
  ```

### Scenario: every warning is actionable

- Given the new file `classify_probe.ads` containing
  ```ada
  package Classify_Probe is
     procedure Create (X : in Integer);
     procedure Create (X : in Float);
  end Classify_Probe;
  ```
- When I run `../bin/hac-bindgen check classify_probe.ads`
- Then there is no error
- And there is no error output
- And I get
  ```text
  classify_probe.ads:3:16: warning HACB0001: procedure Create is not bound: the name Create is already bound: HAC callbacks are keyed by a single name
  Classify_Probe: 1 operation bound, 1 not bound (see warnings)
  ```

### Scenario: pointer-ish declarations are all warned out

- Given the new file `pointer_probe.ads` containing
  ```ada
  with System;
  package Pointer_Probe is
     type Int_Ptr is access Integer;
     procedure Via (P : in Int_Ptr);
     procedure Raw (A : in System.Address);
     procedure Ping (X : in Integer);
     procedure Store (X : in Float);
  end Pointer_Probe;
  ```
- When I run `../bin/hac-bindgen check pointer_probe.ads`
- Then there is no error
- And there is no error output
- And I get
  ```text
  pointer_probe.ads:3:11: warning HACB0003: type Int_Ptr is not bound: no pointer representation across the VM boundary
  pointer_probe.ads:4:21: warning HACB0003: parameter P is not bound: no pointer representation across the VM boundary
  pointer_probe.ads:5:21: warning HACB0014: parameter A is not bound: unchecked address conversions have no defined VM semantics
  Pointer_Probe: 2 operations bound, 2 not bound (see warnings)
  ```

### Scenario: composite and tagged boundary declarations are warned out

- Given the new file `shape_probe.ads` containing
  ```ada
  package Shape_Probe is
     type Point is record
        X, Y : Integer;
     end record;
     type Handle is tagged null record;
     procedure Move (P : in Point);
     procedure Attach (H : in Handle);
  end Shape_Probe;
  ```
- When I run `../bin/hac-bindgen check shape_probe.ads`
- Then there is no error
- And there is no error output
- And I get
  ```text
  shape_probe.ads:6:22: warning HACB0005: parameter P is not bound: composite mapping is deferred to a later profile
  shape_probe.ads:7:24: warning HACB0004: parameter H is not bound: the tool does not own object representation
  Shape_Probe: 0 operations bound, 2 not bound (see warnings)
  ```

### Scenario: nothing is silently dropped

- Given the new file `exotic_probe.ads` containing
  ```ada
  package Exotic_Probe is
     type Ptr is access Integer;
     generic
        type T is private;
     package Gen is
        procedure Op (X : in T);
     end Gen;
     Failure : exception;
  end Exotic_Probe;
  ```
- When I run `../bin/hac-bindgen check exotic_probe.ads`
- Then there is no error
- And there is no error output
- And I get
  ```text
  exotic_probe.ads:2:11: warning HACB0003: type Ptr is not bound: no pointer representation across the VM boundary
  exotic_probe.ads:3:6: warning HACB0007: generic package is not bound: instantiate natively, and bind the instance
  exotic_probe.ads:8:6: warning HACB0011: exception declaration is not bound: Ada exception identity does not cross the boundary
  Exotic_Probe: 0 operations bound, 0 not bound (see warnings)
  ```

## Verification beyond bbt

- Unit tests: not applicable — the bbt scenarios are the test suite.
- SPARK / proof: not applicable.
- Other: the catalogue rows not exercised here stay spec-only until
  the traversal reaches their construct; no golden file is involved —
  every scenario checks the whole expected output with `is`.

## Design implications

Warning format and single-traversal design follow the recorded
decisions in [design_discussions.md](../dev/design_discussions.md):
`check` and `generate` run the same analysis path, so the
classification is defined once and both commands report it identically
([S006]). The `HACBxxxx` identifiers are frozen like the dump format:
adding entries is allowed, renumbering is not.
