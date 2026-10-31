# A009 — Record boundary values <!-- omit from toc -->

Status: Proposed
Source: roadmap M7 (composite boundary values, targeted use case:
the topoproof TopoScript API); the HAC record marshalling was
verified by execution of the HAC 0.45.0 interpreter (probe of
2026-10-31, see Specification).

## Contents <!-- omit from toc -->

- [Need](#need)
- [Intended outcome](#intended-outcome)
- [Scope](#scope)
- [Non-goals](#non-goals)
- [Acceptance criteria](#acceptance-criteria)
- [Specification](#specification)
- [Executable scenarios](#executable-scenarios)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)
- [Open questions](#open-questions)
- [Finalization target](#finalization-target)

## Need

Real APIs exchange structured values: points, vectors, configuration
records. hac-bindgen warns every record boundary value out
([HACB0005]) — the composite marshalling does not exist, although the
HAC VM layout for it is documented in the M2 evidence: composite
values occupy their `Size_of` number of consecutive `Data` elements.
The targeted use case is topoproof's TopoScript API, whose operations
exchange `Point_3D` and `Vector_3D` records.

## Intended outcome

A record type whose components are all bindable scalars is bound:
mirrored HAC-side, and marshalled component-wise — each component
converted through its own conversion, at its own slot offset, the
offsets computed recursively for nested records. `out` and `in out`
record parameters copy back like scalars. Records with a non-bindable
component keep a warning.

## Scope

- The backend dump carries the component list of a record type
  declaration: one component line per component (name, type mark,
  resolution).
- The model carries the component list; the generation computes the
  slot offsets recursively.
- [HACB0005] narrowed: a record root is bound when every component,
  recursively, is a bindable scalar (integer, float, boolean,
  enumeration, or a nested record that is itself bound); it warns
  otherwise, with the reason naming the offending component.
- The e2e scenarios: record `in` exchange, record copy-back.

## Non-goals

- Arrays (as boundary values or as record components): the array
  mapping is deferred ([HACB0005] keeps warning array roots);
  a record with an array component is not bound.
- Discriminated records, variant parts, records with access, task or
  controlled components: warned out as before.
- Records with a `VString` (unconstrained string) component: the
  component's size is not statically known; not bound.
- Records with a handleable (private) component: the handle is an
  Integer and would work mechanically, but the ownership rules of
  [A004] must be thought through first; deferred.
- A record result from an imported *function*: HAC functions' results
  are atomic types only (HAC source, `Size_of` of a function result
  is currently 1); the record result crosses through the
  function-emulation `out` parameter like any other result.

## Acceptance criteria

- A script passes record values to a bound procedure; the native side
  sees the exact component values, and an `out` / `in out` record
  parameter copies back into the script's variable, the e2e scenario
  green.
- A record type with a non-bindable component is warned out with the
  component named in the reason, and every operation using the type
  counts as not bound.
- The registry of the M2 witness (`make witness`) keeps verifying the
  record marshalling.

## Specification

The HAC VM copies, for every imported parameter, `Size_of (parameter)`
stack cells into consecutive `Data` slots (M2 evidence). For a record
type, `Size_of` is the block's variable size — the components' cells
in declaration order, nested records flattened recursively (HAC
source: `Size_of` returns `VSize` for records; verified by execution
today: a script passes two `Point` records to an imported procedure,
the native callback reads each component cell and writes the `out`
record cells back, and the script sees the summed components —
`make witness` verifies it permanently).

The generated callback therefore converts component-wise:

- the model carries, for each bound record type, the component list
  (name, type identity), from the backend dump;
- the generation computes the slot offset of every component
  recursively (a scalar component: one slot; a nested record: its own
  component offsets), and instantiates or reuses the conversion of
  each component's type mark;
- `in` / `in out`: each component read from its slot into the native
  record; `out` / `in out`: after the native call, each component
  written back into its slot — the native subtype checks apply on the
  way back ([S003]).

The backend dump gains one component line per record component —
`component <name> <type mark> resolved <canonical>` — an optional
line inside the existing type declaration block; the dump grammar
grows without a format bump, the reader accepting the new optional
line ([A003] precedent: parameter lines, constraint line).

[HACB0005] keeps warning: array roots, discriminated records, records
with a component that is not itself bound (array, access, VString
component...). The reason names the offending component.

## Executable scenarios

The end-to-end scenarios use the harness of
[A002](../features/A002_facade_generation.md); all scenarios run from
`tests/`.

| Scenario | Behavior |
|---|---|
| A009-01 | a record value crosses the boundary, component-wise |
| A009-02 | record copy-back: `out` / `in out` record parameters |
| A009-03 | a record with a non-bindable component is warned out |

### Scenario: a record value crosses the boundary, component-wise

The native side receives the components of the two `in` records and
writes the `out` record; the script sees the summed components.

- Given the new directory `run`
- Given the new file `run/shape_api.ads` containing
  ```ada
  package Shape_Api is
     type Point is record
        X, Y : Integer;
     end record;
     procedure Move (R : out Point; P : in Point; D : in Point);
  end Shape_Api;
  ```
- Given the new file `run/shape_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Shape_Api is
     procedure Move (R : out Point; P : in Point; D : in Point) is
     begin
        R := (P.X + D.X, P.Y + D.Y);
        Ada.Text_IO.Put_Line
          ("native: moved to" & Integer'Image (R.X)
           & "," & Integer'Image (R.Y));
     end Move;
  end Shape_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/shape_api.ads --output-dir run --hac-package HAC_Shape_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Shape_Api_Native;
  package Witness_Binding renames Shape_Api_Native;
  ```
- Given the new file `run/record_script.adb` containing
  ```ada
  with HAC_Shape_Api;
  with HAT;
  procedure Record_Script is
     P : HAC_Shape_Api.Point := (X => 1, Y => 2);
     D : HAC_Shape_Api.Point := (X => 10, Y => 20);
     R : HAC_Shape_Api.Point;
  begin
     HAC_Shape_Api.Move (R, P, D);
     if R.X = 11 and then R.Y = 22 then
        HAT.Put_Line ("script: components correct.");
     else
        HAT.Put_Line ("script: MISMATCH.");
     end if;
  end Record_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/record_script.adb`
- Then I get
  ```text
  native: moved to 11,22
  script: components correct.
  E2E: script completed.
  ```

### Scenario: record copy-back: out / in out record parameters

The generated callback writes every component of the `out` / `in out`
record back; the native subtype checks apply on the way back.

- Given the new directory `run`
- Given the new file `run/scale_api.ads` containing
  ```ada
  package Scale_Api is
     type Vector is record
        Dx, Dy : Integer;
     end record;
     procedure Scale (V : in out Vector; K : in Integer);
  end Scale_Api;
  ```
- Given the new file `run/scale_api.adb` containing
  ```ada
  package body Scale_Api is
     procedure Scale (V : in out Vector; K : in Integer) is
     begin
        V := (V.Dx * K, V.Dy * K);
     end Scale;
  end Scale_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/scale_api.ads --output-dir run --hac-package HAC_Scale_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Scale_Api_Native;
  package Witness_Binding renames Scale_Api_Native;
  ```
- Given the new file `run/scale_script.adb` containing
  ```ada
  with HAC_Scale_Api;
  with HAT;
  procedure Scale_Script is
     V : HAC_Scale_Api.Vector := (Dx => 3, Dy => 4);
  begin
     HAC_Scale_Api.Scale (V, 2);
     if V.Dx = 6 and then V.Dy = 8 then
        HAT.Put_Line ("script: copy-back correct.");
     else
        HAT.Put_Line ("script: MISMATCH.");
     end if;
  end Scale_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/scale_script.adb`
- Then I get
  ```text
  script: copy-back correct.
  E2E: script completed.
  ```

### Scenario: a record with a non-bindable component is warned out

A record whose component is an array type is not bound; the reason
names the offending component, and the operation using the type is
not bound.

- Given the new file `bad_record.ads` containing
  ```ada
  package Bad_Record is
     type Grid is array (1 .. 10) of Integer;
     type Config is record
        Name_Length : Integer;
        Cells       : Grid;
     end record;
     procedure Apply (C : in Config);
  end Bad_Record;
  ```
- When I successfully run `../bin/hac-bindgen check bad_record.ads`
- Then the output contains `warning HACB0005`
- And the output contains `Cells`
- And the output contains `0 operations bound, 1 not bound`

## Verification beyond bbt

- Unit tests: not applicable — the bbt scenarios are the test suite.
- SPARK / proof: not applicable.
- Other: the HAC facts (record parameters accepted on imported
  declarations, `Size_of` component layout, record copy-back) were
  verified by execution on 2026-10-31: a compile probe
  (declaration + aggregate + call compiles; failure only at
  registration lookup) and the M2 witness probe, now permanent
  (`make witness`).

## Design implications

The composite layout rests on the VM's cell representation, read in
the HAC source and verified by execution — the same evidence standard
as the scalar profile. The component-wise conversion reuses the
existing conversion instantiations: no new conversion kind. The dump
format grows by an optional line, not a format bump.

## Open questions

- Boolean and enumeration component cells: the M2 evidence verified
  enum and Boolean conversions for scalar parameters; the same
  conversions apply to the component cells, verified by the
  witness probe (integer components) and re-verified by the e2e
  scenarios for the other scalar kinds.
- Should the dump carry component default expressions? No consumer
  needs them (same reasoning as [HACB0009]); not carried.

## Finalization target

A new `docs/features/A009_records.md`; the [HACB0005] narrowing joins
[B001](B001_non_bindable_constructs.md); the M2 evidence notes gain
the record marshalling line; the roadmap M7 items are checked at the
same Finalize.
