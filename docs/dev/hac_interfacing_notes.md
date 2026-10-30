# HAC interfacing notes — M2 evidence <!-- omit from toc -->

The interface findings below are verified against HAC 0.45.0, from the
in-tree Alire dependency and its `demo/data_exchange/` sources. The
executable witness in `tests/witness/` exercises the supported scalar
paths and error propagation (`make witness`).

## Callback contract

- `HAC_Sys.Interfacing.Exported_Procedure` is an access-to-procedure
  type accepting `Data : in out HAC_Element_Array`.
- The callback is registered with `Register (BD, Callback, Name)`.
  The map is owned by the `Compiler_Data` referenced by `Build_Data`;
  it is not a process-global registry. Names are converted to uppercase.
  Registering the same full name again replaces its previous entry.
- HAC imports are declarations with `with Import => True`. This works
  both on a subprogram nested in the HAC main and on subprograms in a
  package specification. HAC resolves a package operation by its
  qualified name (for example `WITNESS_API.SAY`); two packages can
  therefore import an operation with the same simple name.
- `Data` is 1-based. Parameters are laid out in declaration order;
  composite values occupy their `Size_of` number of consecutive
  elements. Before calling the adapter, HAC copies `in` and `in out`
  arguments into the array and does not populate `out` elements.
  After the adapter returns, HAC copies `out` and `in out` values back.
- HAC imports are procedures, not native function callbacks. A HAC
  function can wrap an imported procedure whose first `out` parameter
  is the result. The witness verifies the result in `Data (1)`, followed
  by its two input parameters in `Data (2)` and `Data (3)`.
- Registration stores a plain procedure access value; there is no
  callback context or closure. Keep the callback code alive for every
  call through its `Build_Data`.

The `Build_Data`-owned registry and a single script's calls are
synchronous. HAC 0.45.0 provides no re-entrancy or thread-safety
contract for callbacks; generated code must not assume recursive
interpretation or concurrent use of the same environment.

## Boundary representations

The conversions are declared in `HAC_Sys.Interfacing`:

| Native profile | HAC representation | Conversion notes |
|---|---|---|
| `Integer` | `HAC_Integer` (`Interfaces.Integer_64`) | Direct overload. On targets where native `Integer` is narrower, conversions can raise `Constraint_Error`. |
| Integer range type | HAC integer | Instantiate `To_HAC_Any_Integer` / `To_Native_Any_Integer`. Native subtype range checks apply; the witness verifies an out-of-range value is reported rather than silently accepted. |
| Enumeration, including `Boolean` | HAC integer ordinal | Instantiate the enum generic pair. `T'Pos` / `T'Val` are used; the witness verifies `Boolean` and a user enumeration in both directions. |
| `Long_Float` | `HAT.Real` | Direct overload. |
| Floating-point type | `HAT.Real` | Instantiate `To_HAC_Any_Float` / `To_Native_Any_Float`. `HAT.Real` is declared with `System.Max_Digits`; the precision is target-defined. HAC documents its float exponent limits as -308 .. 308 and describes the model as IEEE double precision. |
| `String` | `HAT.VString` | The overload constructs/reads a `VString`; HAC's `VString` is `Ada.Strings.Unbounded.Unbounded_String`. |

`HAC_Type_Error` is raised when a `To_Native` conversion expects a
`HAT.Real` or `VString` but receives a different HAC element kind.
Integer and generic subtype conversions use Ada numeric conversions and
can raise `Constraint_Error` on range overflow. The caller must not
replace those failures with default values.

String conversion uses `HAT.To_VString` and `HAT.To_String`; no
encoding conversion is performed by this interface. HAC character
ordinals are 0 .. 255, so clients must define and preserve their own
byte/character encoding convention. The witness checks string input and
copy-back; it does not claim Unicode transcoding.

## Error behavior and witness coverage

HAC catches exceptions raised by a native callback and raises a HAC VM
`Program_Error` with the prefix `Exception raised in callback, message:`
and the native exception message. The interpreter records this in
`Post_Mortem_Data`; execution stops, and the traceback API reports the
HAC import declaration and calling script locations. The witness checks
this for a `HAC_Type_Error`, a subtype range failure, and an arbitrary
native exception.

`make witness` also verifies:

- a callback declared with `Import` in a package specification;
- package-qualified registrations for two imported operations named
  `Say`;
- a HAC function implemented as an imported procedure with an `out`
  result slot;
- direct and generic integer, float, string, Boolean, and enumeration
  conversions, including `in out` copy-back;
- multiple builds and executions using the same `Build_Data`.

The observable paths needed for generation in M4 are established.
Unspecified behavior is explicitly constrained: callbacks use no
captured per-call state, and recursive/concurrent use of one HAC
environment is unsupported unless HAC documents and tests it later.

## Open analysis questions (M3)

- How much semantic resolution does each candidate backend (Kazakov's
  Ada Syntax Analyzer, Libadalang) provide for the profile: package
  and subprogram identification, parameter modes, result types, local
  subtype chains, predefined-type recognition, source locations?
- Does either backend need project configuration for a single-file
  specification?
- Which backend gives reliable type resolution for the smallest
  dependency cost? Evaluation criteria: coverage of the traversal
  profile, dependency footprint and licence, robustness on
  legal-but-unusual Ada, and integration effort.
