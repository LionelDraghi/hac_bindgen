# A004 — Handle profile: opaque objects across the boundary <!-- omit from toc -->

Status: Proposed
Source: roadmap M6 (handles and enumerations); handle design arbitrated
during the 2026-10-31 exploration (HAC capabilities verified by
execution, access-to-private allocation verified with GNAT 16).

## Contents <!-- omit from toc -->

- [Need](#need)
- [Intended outcome](#intended-outcome)
- [Scope](#scope)
- [Non-goals](#non-goals)
- [Acceptance criteria](#acceptance-criteria)
- [Specification](#specification)
  - [Handle representation](#handle-representation)
  - [The registry helper](#the-registry-helper)
  - [Classification changes](#classification-changes)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: a script creates, uses and drops an opaque object](#scenario-a-script-creates-uses-and-drops-an-opaque-object)
  - [Scenario: an unknown handle is a defined boundary error](#scenario-an-unknown-handle-is-a-defined-boundary-error)
  - [Scenario: the generated files carry the handle machinery](#scenario-the-generated-files-carry-the-handle-machinery)
  - [Scenario: classification of private, tagged, limited and class-wide types](#scenario-classification-of-private-tagged-limited-and-class-wide-types)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)
- [Open questions](#open-questions)
- [Finalization target](#finalization-target)

## Need

The scalar profile (A002) binds numbers, booleans and enumerations.
The most common binding shape beyond that is an opaque object the
script creates, passes to operations, and eventually releases — a
`Widget`, a `Connection`, a `Document`. Today such types warn out
([HACB0004]): the tool does not own the object representation. HAC
cannot hold a native object: it has no `private type` (verified:
HAC 0.45.0 rejects the declaration) and no composite boundary
representation. But the script can hold a number designating the
object, with the native adapter resolving that number to the real
object at each call.

## Intended outcome

A private or tagged private type used as a boundary value is bound as
a **handle**: an integer the script holds, resolved by the generated
adapter to a native object it owns. Operations taking or returning
such a type are bound and counted in the summary. An explicit
generated `Drop` operation releases the registry entry; using a
dropped or never-issued handle is a defined boundary error, never a
silent reinterpretation ([S003]) and never a dangling access.

## Scope

- The classification of private/tagged private types as handleable,
  and the narrowing of [HACB0004] (limited, interface, class-wide and
  abstract types stay non-bindable).
- The handle machinery of the generated files: the HAC-side handle
  subtype, the `Drop` operation, the registry helper files, the
  adapter callback changes.
- The end-to-end and generate-only scenarios below.

## Non-goals

- Records, arrays and other composites as boundary values
  ([HACB0005] unchanged; they may become handles in a later
  profile — the mechanism is the same).
- `limited`, interface, class-wide and abstract types.
- Automatic lifetime management: the registry never frees an entry
  on its own; ownership decisions belong to the application
  ([HACB0016] spirit). The helper-registry *library* as a reusable
  Alire crate stays a gadget; this page emits a self-contained
  helper source.
- `out` / `in out` copy-back ([A002-06], separate M6 item).
- Several bound packages in one run (M6 item; the helper is emitted
  once per run — the multi-package dedup question is that item's).

## Acceptance criteria

- A script creates opaque objects through a bound function, passes
  the returned handles to bound procedures, and drops them; the
  native side sees the real objects, reference semantics included
  (the same handle designates the same object across calls).
- A handle the registry never issued, or a dropped handle, stops the
  script with a defined boundary error naming the type ([C002],
  [S003], [S007]).
- `check` classifies private/tagged-private parameters and results as
  bound (no [HACB0004] warning); limited, class-wide and record
  boundary values keep their warnings.
- The scenarios below are green and promoted to
  `docs/features/A004_handles.md` at Finalize.

## Specification

### Handle representation

HAC-side, a handleable type `Widget` becomes exactly one mirror
declaration:

```text
subtype Widget_Handle is Integer;
```

A subtype (not `type ... is new Integer`, which HAC rejects): the
script's typing is documentary, the boundary type is the integer.
Operations are declared on the handle: `procedure Draw (W : in
Widget_Handle);`, `function Make_Widget return Widget_Handle;`.

Native side, the adapter resolves handles through a registry: one
entry per type, keyed by a monotonically increasing handle. The
registry owns a **copy** of every object that crosses native→HAC
(`new Widget'(Result)` — legal from a client, verified with GNAT 16,
for definite and indefinite full views):

- A function returning a handleable type allocates a registry copy
  and returns a fresh handle; two creations of equal values yield two
  distinct handles and two distinct objects.
- An `in` parameter of a handleable type resolves the handle to the
  registry object and passes it as-is: reference semantics, no copy
  in either direction.
- `Drop` deallocates the registry copy and removes the entry; any
  later use of that handle is the unknown-handle boundary error.
- An unknown handle raises the boundary error whose message is
  `unknown <Type> handle <N>`; the exception propagates to HAC's
  error mechanism ([S007], class 2) and stops the script.
- Entries not dropped stay until process end; no automatic
  reclamation, no finalizer, no weak references.

### The registry helper

When a run binds at least one handleable type, `generate` emits a
self-contained generic helper next to the adapter:

| File | Content |
|---|---|
| `hac_bindgen_handles.ads` | the generic registry package |
| `hac_bindgen_handles.adb` | its body |

Contract of the generic (instantiated once per handleable type in the
adapter):

```ada
generic
   type Native_Type (<>) is private;
   Debug_Name : String;
package Hac_Bindgen_Handles is
   type Handle is new Integer range 1 .. Integer'Last;
   Unknown_Handle : exception;

   type Native_Access is access Native_Type;

   function To_Handle (V : Native_Type) return Handle;
   --  Copy V into the registry, return its fresh handle.

   function From_Handle (H : Handle) return Native_Access;
   --  The registry object designated by H; raises Unknown_Handle
   --  with message "unknown <Debug_Name> handle <N>" when H is not
   --  a live entry.

   procedure Drop (H : Handle);
   --  Deallocate the registry object and remove the entry; a later
   --  From_Handle of H raises Unknown_Handle.
end Hac_Bindgen_Handles;
```

The helper files are generated, carry the [S002] header, and are
never hand-edited; the generated adapter is the only wither.

### Classification changes

- The dump already carries what classification needs — the
  definition spelling of a private partial view
  (`definition tagged private`, `definition private`,
  `definition limited private`, `definition new Base with private`).
  No format bump ([A003]).
- A type whose definition spelling ends in `private` is handleable,
  **unless** the spelling contains `limited` or `abstract`. Subtypes
  resolve through the root of the chain, as in [B001].
- [HACB0004] narrows to: limited private views, interface types,
  class-wide type marks (type mark ending in `'Class`) and abstract
  types. Private and tagged private boundary values no longer warn.
- [HACB0003] (access types) and [HACB0005] (composites) are
  unchanged.
- Operations with a handleable boundary value count as bound in the
  summary; the generated `Drop_<T>` operation is part of the bound
  surface and is registered like any other operation.

## Executable scenarios

The end-to-end scenarios use the harness of [A002]: files in `run/`,
witness built with the e2e project, script run by the static witness
main. All scenarios run from `tests/`.

| Scenario | Behavior |
|---|---|
| A004-01 | a script creates, uses and drops an opaque object |
| A004-02 | an unknown handle is a defined boundary error |
| A004-03 | the generated files carry the handle machinery |
| A004-04 | classification of private, tagged, limited and class-wide types |

### Scenario: a script creates, uses and drops an opaque object

- Given the new directory `run`
- Given the new file `run/widget_api.ads` containing
  ```ada
  package Widget_Api is
     type Widget is tagged private;
     function Make_Widget return Widget;
     procedure Draw (W : in Widget);
     procedure Close (W : in Widget);
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
     Next_Id : Integer := 0;
     function Make_Widget return Widget is
     begin
        Next_Id := Next_Id + 1;
        Ada.Text_IO.Put_Line ("native: make widget"
                              & Integer'Image (Next_Id));
        return Widget'(Id => Next_Id);
     end Make_Widget;
     procedure Draw (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: draw widget"
                              & Integer'Image (W.Id));
     end Draw;
     procedure Close (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: close widget"
                              & Integer'Image (W.Id));
     end Close;
  end Widget_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/widget_api.ads --output-dir run --hac-package HAC_Widget_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Widget_Api_Native;
  package Witness_Binding renames Widget_Api_Native;
  ```
- Given the new file `run/widget_script.adb` containing
  ```ada
  with HAC_Widget_Api;
  procedure Widget_Script is
     W1, W2 : HAC_Widget_Api.Widget_Handle;
  begin
     W1 := HAC_Widget_Api.Make_Widget;
     W2 := HAC_Widget_Api.Make_Widget;
     HAC_Widget_Api.Draw (W1);
     HAC_Widget_Api.Draw (W2);
     HAC_Widget_Api.Close (W1);
     HAC_Widget_Api.Drop_Widget (W1);
  end Widget_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/widget_script.adb`
- Then I get
  ```text
  native: make widget 1
  native: make widget 2
  native: draw widget 1
  native: draw widget 2
  native: close widget 1
  E2E: script completed.
  ```

### Scenario: an unknown handle is a defined boundary error

- Given the new directory `run`
- Given the new file `run/widget_api.ads` containing
  ```ada
  package Widget_Api is
     type Widget is tagged private;
     function Make_Widget return Widget;
     procedure Draw (W : in Widget);
     procedure Close (W : in Widget);
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
     Next_Id : Integer := 0;
     function Make_Widget return Widget is
     begin
        Next_Id := Next_Id + 1;
        Ada.Text_IO.Put_Line ("native: make widget"
                              & Integer'Image (Next_Id));
        return Widget'(Id => Next_Id);
     end Make_Widget;
     procedure Draw (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: draw widget"
                              & Integer'Image (W.Id));
     end Draw;
     procedure Close (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: close widget"
                              & Integer'Image (W.Id));
     end Close;
  end Widget_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/widget_api.ads --output-dir run --hac-package HAC_Widget_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Widget_Api_Native;
  package Witness_Binding renames Widget_Api_Native;
  ```
- Given the new file `run/forged_script.adb` containing
  ```ada
  with HAC_Widget_Api;
  procedure Forged_Script is
  begin
     HAC_Widget_Api.Draw (99);
  end Forged_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I run `./run/witness_main run/forged_script.adb`
- Then the exit code is `1`
- And the error output contains `HAC VM exception:`
- And the error output contains `unknown Widget handle 99`

### Scenario: the generated files carry the handle machinery

- Given the new directory `run`
- Given the new file `run/widget_api.ads` containing
  ```ada
  package Widget_Api is
     type Widget is tagged private;
     function Make_Widget return Widget;
     procedure Draw (W : in Widget);
     procedure Close (W : in Widget);
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
     Next_Id : Integer := 0;
     function Make_Widget return Widget is
     begin
        Next_Id := Next_Id + 1;
        Ada.Text_IO.Put_Line ("native: make widget"
                              & Integer'Image (Next_Id));
        return Widget'(Id => Next_Id);
     end Make_Widget;
     procedure Draw (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: draw widget"
                              & Integer'Image (W.Id));
     end Draw;
     procedure Close (W : in Widget) is
     begin
        Ada.Text_IO.Put_Line ("native: close widget"
                              & Integer'Image (W.Id));
     end Close;
  end Widget_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/widget_api.ads --output-dir run --hac-package HAC_Widget_Api`
- Then there is a file `run/hac_bindgen_handles.ads`
- And there is a file `run/hac_bindgen_handles.adb`
- And the file `run/hac_widget_api.ads` contains `subtype Widget_Handle is Integer;`
- And the file `run/hac_widget_api.ads` contains `procedure Drop_Widget (W : in Widget_Handle);`
- And the file `run/widget_api_native.adb` contains `new Hac_Bindgen_Handles`
- And the output contains `3 operations bound, 0 not bound`

### Scenario: classification of private, tagged, limited and class-wide types

- Given the new directory `run`
- Given the new file `run/mixed_api.ads` containing
  ```ada
  package Mixed_Api is
     type Handleable is tagged private;
     type Locked is limited private;
     type Point is record
        X, Y : Integer;
     end record;
     procedure Op1 (H : in Handleable);
     procedure Op2 (L : in Locked);
     procedure Op3 (P : in Point);
     procedure Op4 (H : in Handleable'Class);
  private
     type Handleable is tagged record
        Id : Integer;
     end record;
     type Locked is record
        V : Float;
     end record;
  end Mixed_Api;
  ```
- When I successfully run `../bin/hac-bindgen check run/mixed_api.ads`
- Then the exit code is `0`
- And the output contains `warning HACB0004`
- And the output contains `warning HACB0005`
- And the output contains `1 operation bound, 3 not bound (see warnings)`
- And the output does not contain `Op1`

## Verification beyond bbt

- Unit tests: not applicable — the bbt scenarios are the test suite.
- SPARK / proof: not applicable.
- Other: the HAC facts (no `private type`, no `type ... is new
  Integer`, subtypes accepted) and the GNAT facts (access-to-private
  allocation from a client) were verified by execution during the
  2026-10-31 exploration; the scenarios re-prove them end to end.

## Design implications

The registry never frees automatically and the helper is emitted, not
published as a library: these follow the ownership decision recorded
in [B001] ([HACB0016] — ownership decisions belong to the
application) and keep the generated façade self-contained. The
`Drop` operation is the explicit-ownership answer: it was added to
the design because without it, no bound program could release registry
memory. Reference semantics keep [S003]: a handle never stands for a
value, only for the registry object it designates; unknown handles
are [C002] boundary errors, never silent reinterprets.

## Open questions

None: representation, registry contract, Drop, and classification
were arbitrated during the exploration; the remaining shape decisions
(native `Handle` as a distinct subtype of `Integer`, the container
behind the registry) are implementation details that do not constrain
the behavior specified here.

## Finalization target

`docs/features/A004_handles.md`; [B001] catalogue and classification
rules updated (HACB0004 narrowed, new handle rules) at the same
Finalize.
