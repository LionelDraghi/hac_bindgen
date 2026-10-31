# A006 — Strings end to end <!-- omit from toc -->

Real APIs exchange text with the scripts: messages, names, file
paths. The boundary conversion exists in HAC — the `String` overloads
of `To_HAC` / `To_Native`, the `VString` copy-back of the M2
evidence — and this page owns the string mapping: the script sees a
`VString` (HAT), constructs one with `+"..."`, and gets real string
values back. Ownership is **copy both ways**, demonstrated end to
end ([S003]). The finding that shaped it: the VM exchanges only
VStrings across the boundary, so a constrained string subtype warns
out ([HACB0018]) and an `out` string parameter stays refused
([HACB0008]).

## Contents <!-- omit from toc -->

- [Need](#need)
- [Intended outcome](#intended-outcome)
- [Scope](#scope)
- [Non-goals](#non-goals)
- [Acceptance criteria](#acceptance-criteria)
- [Specification](#specification)
  - [String mapping](#string-mapping)
  - [Ownership: copy both ways](#ownership-copy-both-ways)
  - [Copy-back shapes](#copy-back-shapes)
  - [Backend: index constraints](#backend-index-constraints)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: a script passes a string to the native side](#scenario-a-script-passes-a-string-to-the-native-side)
  - [Scenario: a function returns a string](#scenario-a-function-returns-a-string)
  - [Scenario: string copy-back](#scenario-string-copy-back)
  - [Scenario: a bounded string subtype is warned out](#scenario-a-bounded-string-subtype-is-warned-out)
  - [Scenario: an index constraint is dumped](#scenario-an-index-constraint-is-dumped)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)
- [Open questions](#open-questions)
- [Finalization target](#finalization-target)

## Need

Real APIs exchange text with the scripts: messages, names, file
paths. The boundary conversion exists — HAC's `String` overloads of
`To_HAC` / `To_Native`, the M2 witness's `VString` copy-back — but
hac-bindgen warns every string parameter out ([HACB0005], string
roots) and generates nothing. The ownership question of [S003] was
the blocker: what each side owns when a string crosses.

## Intended outcome

A `String` parameter or result is bound: the script sees a
`VString` (HAT), constructs one with `+"..."`, and gets real string
values back. Ownership is **copy both ways**, demonstrated end to
end: no aliasing across the boundary, each side owning its own
representation. A bounded string subtype is mirrored verbatim and
its length check applies at the crossing.

## Scope

- The string mapping and conversions, exercised through `generate`.
- The narrowing of [HACB0005] (string roots no longer warn; arrays
  and records do).
- The backend index-constraint fix (it crashed on `subtype T is
  String (1 .. 8)`); its regression scenario lives in
  [A003](A003_interchange_dump.md).
- The e2e and check scenarios below.

## Non-goals

- Encodings: HAC character ordinals are 0 .. 255; the M2 evidence
  states clients define their own convention — no transcoding here.
- Arrays and records as boundary values ([HACB0005] unchanged).
- Any array type other than `String` itself as a boundary value.
- Functions with unconstrained `out` / `in out` parameters stay
  warned ([HACB0008]).

## Acceptance criteria

- A script passes a string to a bound procedure; the native side
  sees the exact text; neither side observes the other's mutation
  (copy semantics demonstrated, not assumed).
- A bound function returns a native string; the script receives a
  `VString` and compares it.
- An `out` / `in out` string parameter copies back; a bounded
  string subtype warns [HACB0018] (HAC exchanges only VStrings).
- An index-constrained subtype no longer crashes the backend; the
  dump carries `constraint 1 .. 8` for `subtype Short_Text is
  String (1 .. 8)`.
- The scenarios below are green; the regression scenario lives in
  [A003](A003_interchange_dump.md).

## Specification

### String mapping

- An unconstrained `String` type mark maps to `HAT.VString` on the
  HAC side — the same mapped-mark rule as `Long_Float → Real`
  ([A002]). HAC rejects unconstrained `String` parameters (verified:
  "string not supported as parameter"), and accepts `VString`
  parameters, `VString` results, and the `+"..."` construction.
- A bounded string subtype (`subtype Short_Text is String (1 .. 8)`)
  does **not** cross the boundary: HAC accepts its declaration, but
  rejects a `VString` actual for such a parameter, and the VM's
  copy-back unchecked-converts the `VString` register into the
  script's array cells, which corrupts the value (verified by
  execution). It warns [HACB0018]; the dump still carries its
  constraint (see the backend section), for the model's
  completeness.

### Ownership: copy both ways

The conversion mechanics of HAC 0.45.0 (read in `hac_sys-interfacing.adb`)
settle the ownership question of [S003]:

- native→HAC: `To_HAC (String)` **copies** the text into a `VString`
  owned by the HAC representation;
- HAC→native: `To_Native` returns `String` — a fresh value the
  callback owns.

No pointer crosses, nothing is shared: each side owns its copy,
demonstrated by the no-aliasing scenario (the native side modifies
its copy; the script's variable is unchanged, and the reverse).

### Copy-back shapes

Same layout and rules as the scalar copy-back of [A002], with one
addition — the native local of an `out` string parameter:

- `in out`: the local is initialized from the read value (so its
  bounds come from the value), the native operation runs, and the
  local is written back: `To_HAC` copies it into a fresh `VString`.
- `out`: **not bindable** — strings are by-reference on the native
  side, the callee cannot size the container, and no value exists to
  read: [HACB0008], reason "the native string container is
  by-reference: the callee cannot size it". The copy shapes above
  concern `in` and `in out` only; bounded string subtypes are not
  bound at all ([HACB0018]).
- `in out` requires the native operation to preserve the length: the
  container belongs to the script's copy; a length-changing
  assignment raises `Constraint_Error`, which propagates to HAC
  ([S007], class 2) — a defined boundary error, never a truncation
  ([S003]).

### Backend: index constraints

The backend crashed on `subtype Short_Text is String (1 .. 8)`:
`As_Range_Constraint` applied to a composite constraint raises
`Constraint_Error` (reproduced before the fix; same defect family as
the parameterless crash of [A003]). The fix: dispatch on the
constraint node kind, and report an index constraint when it
constrains exactly one index with a static range — the dump carries
the same `constraint <Low> .. <High>` line as a range constraint.
Discriminant constraints, more than one index, or dynamic bounds
report `constraint (dynamic)`.

The dump grammar is unchanged: no format bump ([A003]). The reader
rebuilds the mirror text with the base root's syntax: `range` for
scalars, parentheses for array and string roots — the grammar line
itself does not carry the syntax.

## Executable scenarios

The end-to-end scenarios use the harness of
[A002](A002_facade_generation.md); all scenarios run from `tests/`.

| Scenario | Behavior |
|---|---|
| A006-01 | a script passes a string to the native side |
| A006-02 | a function returns a string |
| A006-03 | string copy-back |
| A006-04 | the refused string shapes are warned out |
| (regression) | an index constraint is dumped (the [A003](A003_interchange_dump.md) scenario) |

### Scenario: a script passes a string to the native side

- Given the new directory `run`
- Given the new file `run/door_api.ads` containing
  ```ada
  package Door_Api is
     procedure Open (Path : in String);
  end Door_Api;
  ```
- Given the new file `run/door_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Door_Api is
     procedure Open (Path : in String) is
     begin
        Ada.Text_IO.Put_Line ("native: open """ & Path & """");
     end Open;
  end Door_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/door_api.ads --output-dir run --hac-package HAC_Door_Api`
- Then the output contains `1 operation bound, 0 not bound`
- And the file `run/hac_door_api.ads` contains `procedure Open (Path : in VString) with Import => True;`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Door_Api_Native;
  package Witness_Binding renames Door_Api_Native;
  ```
- Given the new file `run/door_script.adb` containing
  ```ada
  with HAC_Door_Api;
  with HAT; use HAT;
  procedure Door_Script is
  begin
     HAC_Door_Api.Open (+"front door");
  end Door_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/door_script.adb`
- Then I get
  ```text
  native: open "front door"
  E2E: script completed.
  ```

### Scenario: a function returns a string

- Given the new directory `run`
- Given the new file `run/greet_api.ads` containing
  ```ada
  package Greet_Api is
     function Greet (Name : in String) return String;
  end Greet_Api;
  ```
- Given the new file `run/greet_api.adb` containing
  ```ada
  package body Greet_Api is
     function Greet (Name : in String) return String is
     begin
        return "Hello, " & Name & "!";
     end Greet;
  end Greet_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/greet_api.ads --output-dir run --hac-package HAC_Greet_Api`
- Then the output contains `1 operation bound, 0 not bound`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Greet_Api_Native;
  package Witness_Binding renames Greet_Api_Native;
  ```
- Given the new file `run/greet_script.adb` containing
  ```ada
  with HAC_Greet_Api;
  with HAT; use HAT;
  procedure Greet_Script is
     Message : VString := HAC_Greet_Api.Greet (+"world");
  begin
     if Message = +"Hello, world!" then
        HAT.Put_Line ("script: greeting checked");
     end if;
  end Greet_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/greet_script.adb`
- Then I get
  ```text
  script: greeting checked
  E2E: script completed.
  ```

### Scenario: string copy-back

The native operation preserves the length: the container is the
script copy's.

- Given the new directory `run`
- Given the new file `run/fill_api.ads` containing
  ```ada
  package Fill_Api is
     procedure Mask_First (S : in out String);
  end Fill_Api;
  ```
- Given the new file `run/fill_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Fill_Api is
     procedure Mask_First (S : in out String) is
     begin
        S (S'First) := '*';
        Ada.Text_IO.Put_Line ("native: masked " & S);
     end Mask_First;
  end Fill_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/fill_api.ads --output-dir run --hac-package HAC_Fill_Api`
- Then the output contains `1 operation bound, 0 not bound`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Fill_Api_Native;
  package Witness_Binding renames Fill_Api_Native;
  ```
- Given the new file `run/fill_script.adb` containing
  ```ada
  with HAC_Fill_Api;
  with HAT; use HAT;
  procedure Fill_Script is
     M : VString := +"text";
  begin
     HAC_Fill_Api.Mask_First (M);
     if M = +"*ext" then
        HAT.Put_Line ("script: masked ok");
     end if;
  end Fill_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/fill_script.adb`
- Then I get
  ```text
  native: masked *ext
  script: masked ok
  E2E: script completed.
  ```

### Scenario: the refused string shapes are warned out

The two refused shapes: a bounded string subtype as a boundary value
([HACB0018] — the VM exchanges only VStrings), and an `out` string
parameter ([HACB0008] — the container is by-reference, the callee
cannot size it).

- Given the new directory `run`
- Given the new file `run/bounded_api.ads` containing
  ```ada
  package Bounded_Api is
     subtype Short_Text is String (1 .. 8);
     procedure Check (S : in Short_Text);
     procedure Fill (S : out String);
  end Bounded_Api;
  ```
- When I successfully run `../bin/hac-bindgen check run/bounded_api.ads`
- Then the exit code is `0`
- And the output contains `warning HACB0018`
- And the output contains `HAC exchanges only VStrings across the boundary`
- And the output contains `warning HACB0008`
- And the output contains `the callee cannot size it`
- And the output contains `0 operations bound, 2 not bound (see warnings)`

### Scenario: an index constraint is dumped

This is the regression scenario of the backend fix; it lives in
[A003](A003_interchange_dump.md).

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
    subtype Short_Text is String (1 .. 8);
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    subtype Short_Text loc probe_fixture.ads:2:13 base String resolved standard.String
      constraint 1 .. 8
  end Probe_Fixture
  ```
- And there is no error output

## Verification beyond bbt

- Unit tests: not applicable — the bbt scenarios are the test suite.
- SPARK / proof: not applicable.
- Other: the HAC facts (unconstrained `String` rejected,
  `VString` accepted, `+"..."`, bounded string subtypes accepted as
  declarations and parameters) and the conversion mechanics
  (`To_HAC (String)` / `To_Native return String` copy semantics, read
  in `hac_sys-interfacing.adb`) were verified during the
  2026-11-01 probes; the e2e scenarios re-prove the binding side,
  including the copy ownership.

## Design implications

Copy-both-ways answers the ownership question of [S003] by
construction: nothing shared, nothing aliased, every side owns its
representation — no lifetime decision is left to the application for
strings. The length-preservation rule of `in out` strings keeps [S003]: the
container belongs to the caller's copy, and a length change is a
defined boundary error, never a truncation. The index-constraint fix keeps [A003]'s format frozen:
one constraint line, whatever the constraint kind; the mirror syntax
is a reader-side decision driven by the base root's kind.
