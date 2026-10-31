# A002 extension — `out` / `in out` copy-back <!-- omit from toc -->

Status: Proposed
Source: roadmap M6 ([A002-06], [HACB0008]); HAC shapes verified by
execution of the HAC 0.45.0 interpreter (2026-11-01 probes).

## Contents <!-- omit from toc -->

- [Need](#need)
- [Intended outcome](#intended-outcome)
- [Scope](#scope)
- [Non-goals](#non-goals)
- [Acceptance criteria](#acceptance-criteria)
- [Specification](#specification)
  - [What copy-back means at the boundary](#what-copy-back-means-at-the-boundary)
  - [HAC-side shapes](#hac-side-shapes)
  - [What is and is not supported](#what-is-and-is-not-supported)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: a procedure writes results back to the script](#scenario-a-procedure-writes-results-back-to-the-script)
  - [Scenario: copy-back is refused where it cannot be generated](#scenario-copy-back-is-refused-where-it-cannot-be-generated)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)
- [Open questions](#open-questions)
- [Finalization target](#finalization-target)

## Need

HAC copies `in` and `in out` arguments into the callback array before
the call, and copies `out` and `in out` values back after ([M2]
evidence) — the copy-back semantics is demonstrated, not assumed
anymore. But hac-bindgen still warns every `out` / `in out` parameter
([HACB0008]): a large part of any real API writes its results through
parameters, and today's user must wrap those operations by hand —
exactly the boilerplate this tool exists to remove.

## Intended outcome

`out` and `in out` parameters of bindable scalar types are bound:
the generated callback reads its `in`/`in out` arguments, calls the
native operation, and converts the results back into their `Data`
slots — HAC copies them back into the script's variables. The mode
appears in the generated HAC-side signatures. Where copy-back cannot
be generated, [HACB0008] stays, with a sharper reason.

## Scope

- The mode-aware callback emission: argument layout unchanged (one
  slot per parameter), read before, write back after.
- The HAC-side declarations carrying the real modes.
- The classification: [HACB0008] retired for scalar procedure
  parameters, kept for the refused shapes (functions, `out` of a
  handleable type).
- The scenarios below, which join
  [A002](../features/A002_facade_generation.md) (the reserved
  A002-06) and the [B001](../features/B001_non_bindable_constructs.md)
  catalogue at Finalize.

## Non-goals

- Strings and composites as out/in out parameters ([HACB0005] keeps
  warning them; strings are the next M6 item).
- Functions with `out` / `in out` parameters: HAC's functions have
  `in`-only parameters (verified: the declaration is a parse error),
  so they stay non-bindable.
- `out` parameters of handleable types (see the classification
  section: the native object cannot be default-constructed by the
  callback).
- Access types as out/in out parameters ([HACB0003] unchanged).

## Acceptance criteria

- A script calls a bound procedure with an `in out` parameter and an
  `out` parameter; after each call, the script's variables carry the
  native results — end to end, through the real HAC copy-back.
- The generated HAC-side declarations carry the real modes; the
  imported callbacks match them.
- A function with an `out` parameter, and an `out` parameter of a
  handleable type, are warned `HACB0008` with the sharp reason;
  procedures with scalar `out` / `in out` parameters no longer warn.
- The scenarios below are green; A002-06 joins
  [A002](../features/A002_facade_generation.md) at Finalize.

## Specification

### What copy-back means at the boundary

The [M2] evidence pins the HAC mechanics: `in` and `in out`
arguments are copied into the callback array before the call; `out`
elements are not populated; after the callback returns, HAC copies
`out` and `in out` values back. Therefore, in the generated callback:

- The slot layout is unchanged: one slot per parameter, declaration
  order, function result in slot 1.
- `in`: read-only, as today.
- `in out`: the argument is read into a native local before the
  call, and the local is converted back into its slot after the
  call — the native subtype check applies on the way back, exactly
  like on the way in ([S003]).
- `out`: a native local is declared (never read), passed to the
  native operation, and converted into its slot after the call.

### HAC-side shapes

- A bound procedure keeps its modes in the HAC-side public
  declaration: `procedure Inc (X : in out Integer) with Import =>
  True;` — HAC imports accept `out` and `in out` modes in a package
  specification's private part (verified by execution; the redeclare
  in a body is a duplicate-identifier error, which the generator
  never does).
- A bound function's private callback declares the modes too, and
  its public wrapper passes them through.

### What is and is not supported

- Bound: `out` / `in out` of scalar types — standard `Integer` /
  `Long_Float`, user-defined range types, subtypes, enumerations
  including `Boolean` ([A002]'s conversion table, plus the return
  conversion).
- Bound: `in out` of a handleable type — the registry object is
  passed in place (reference semantics, [A004]), and HAC copies the
  unchanged handle value back; no re-handle, no copy.
- Refused, [HACB0008] with reason "HAC functions have in-only
  parameters": an `out` / `in out` parameter of a bound **function**.
- Refused, [HACB0008] with reason "the callback cannot
  default-construct the native object": an `out` parameter of a
  handleable type — the callback owns registry copies, and a fresh
  `out` value would need an uninitialized native object, which an
  indefinite full view forbids.
- Everything else is unchanged: the mode warning of [B001] keeps its
  location (the parameter's own location) and stable identifier.

## Executable scenarios

The end-to-end scenario uses the harness of
[A002](../features/A002_facade_generation.md); all scenarios run from
`tests/`.

| Scenario | Behavior |
|---|---|
| A002-06 | a procedure writes results back to the script |
| (new) | an in out handle parameter is modified in place |
| (new) | copy-back is refused where it cannot be generated |

### Scenario: a procedure writes results back to the script

- Given the new directory `run`
- Given the new file `run/count_api.ads` containing
  ```ada
  package Count_Api is
     type Level is range 0 .. 100;
     type Light is (Red, Amber, Green);
     procedure Bump (X : in out Level);
     procedure Reset (X : out Level);
     procedure Paint (L : out Light);
  end Count_Api;
  ```
- Given the new file `run/count_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Count_Api is
     procedure Bump (X : in out Level) is
     begin
        X := X + 1;
        Ada.Text_IO.Put_Line ("native: bumped to"
                              & Level'Image (X));
     end Bump;
     procedure Reset (X : out Level) is
     begin
        X := 0;
     end Reset;
     procedure Paint (L : out Light) is
     begin
        L := Green;
     end Paint;
  end Count_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/count_api.ads --output-dir run --hac-package HAC_Count_Api`
- Then the output contains `3 operations bound, 0 not bound`
- And the file `run/hac_count_api.ads` contains `procedure Bump (X : in out Integer) with Import => True;`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Count_Api_Native;
  package Witness_Binding renames Count_Api_Native;
  ```
- Given the new file `run/count_script.adb` containing
  ```ada
  with HAC_Count_Api;
  with HAT;
  procedure Count_Script is
     N : Integer := 40;
     L : HAC_Count_Api.Light;
  begin
     HAC_Count_Api.Bump (N);
     HAC_Count_Api.Reset (N);
     if N = 0 then
        HAT.Put_Line ("script: reset ok");
     end if;
     HAC_Count_Api.Paint (L);
     if L = HAC_Count_Api.Green then
        HAT.Put_Line ("script: paint ok");
     end if;
  end Count_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/count_script.adb`
- Then I get
  ```text
  native: bumped to 41
  script: reset ok
  script: paint ok
  E2E: script completed.
  ```

### Scenario: an in out handle parameter is modified in place

- Given the new directory `run`
- Given the new file `run/widget_api.ads` containing
  ```ada
  package Widget_Api is
     type Widget is tagged private;
     function Make_Widget return Widget;
     procedure Age (W : in out Widget);
     procedure Draw (W : in Widget);
  private
     type Widget is tagged record
        Id : Integer;
     end record;
  end Widget_Api;
  ```
- Given the new file `run/widget_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Widget_Api is
     function Make_Widget return Widget is
        (Id => 1);
     procedure Age (W : in out Widget) is
     begin
        W := (Id => W.Id * 10);
        Ada.Text_IO.Put_Line ("native: aged widget");
     end Age;
     procedure Draw (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: draw widget"
                              & Integer'Image (W.Id));
     end Draw;
  end Widget_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/widget_api.ads --output-dir run --hac-package HAC_Widget_Api`
- Then the output contains `3 operations bound, 0 not bound`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Widget_Api_Native;
  package Witness_Binding renames Widget_Api_Native;
  ```
- Given the new file `run/widget_script.adb` containing
  ```ada
  with HAC_Widget_Api;
  procedure Widget_Script is
     W : HAC_Widget_Api.Widget_Handle := HAC_Widget_Api.Make_Widget;
  begin
     HAC_Widget_Api.Age (W);
     HAC_Widget_Api.Draw (W);
  end Widget_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/widget_script.adb`
- Then I get
  ```text
  native: aged widget
  native: draw widget 10
  E2E: script completed.
  ```

### Scenario: copy-back is refused where it cannot be generated

- Given the new directory `run`
- Given the new file `run/refused_api.ads` containing
  ```ada
  package Refused_Api is
     type Widget is tagged private;
     function Trick (X : out Integer) return Integer;
     procedure Swap (W : out Widget);
  private
     type Widget is tagged record
        Id : Integer;
     end record;
  end Refused_Api;
  ```
- When I successfully run `../bin/hac-bindgen check run/refused_api.ads`
- Then the exit code is `0`
- And the output contains `warning HACB0008`
- And the output contains `HAC functions have in-only parameters`
- And the output contains `the callback cannot default-construct the native object`
- And the output contains `0 operations bound, 2 not bound (see warnings)`

## Verification beyond bbt

- Unit tests: not applicable — the bbt scenarios are the test suite.
- SPARK / proof: not applicable.
- Other: the HAC facts (imports with `out` / `in out` in a package
  specification's private part accepted; a function with an `out`
  parameter rejected; a redeclaration in the body rejected) were
  verified by execution of the HAC 0.45.0 interpreter during the
  2026-11-01 probes; the e2e scenario re-proves the copy-back side.

## Design implications

The argument layout of [A002] is unchanged — copy-back adds the
write-back pass, nothing moves. The [S003] rule is preserved twice:
the `in out` write-back goes through the same conversion
instantiation as the read (the native subtype check applies both
ways), and no failure is replaced by a default value. The `Drop`-like
ownership question does not arise: scalars cross by value, and the
registry's reference semantics are untouched.

## Open questions

None: the supported shapes were settled by the HAC probes, and the
refused shapes keep the stable [HACB0008] identifier with sharper
reasons. The exact wording of the write-back expressions is an
implementation detail.

## Finalization target

[A002](../features/A002_facade_generation.md) gains the A002-06
scenario and the copy-back rules; the [B001](../features/B001_non_bindable_constructs.md)
catalogue narrows [HACB0008] (functions, out-of-handleable).
