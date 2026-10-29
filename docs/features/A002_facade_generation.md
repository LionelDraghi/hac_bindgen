# A002 — Facade generation: the scalar profile

The core feature: hac-bindgen generates the scripting façade from the
supplied API ([S006], [S009]). This page covers the first profile:
one package, procedures and functions with `in` parameters, and the
scalar types HAC supports natively. Wider traits (handles,
enumerations, strings) get their own `Annn` page when their mapping is
demonstrated end to end.

Status: specified, not yet executable. Each planned scenario below
moves to bbt form in this page as soon as the generation chain it
exercises works; the page then becomes the executable documentation
([S008]).

## What `generate` produces

Given a package specification `geometry.ads`, `generate` writes into
the output directory (default `generated/`):

| File | Content |
|---|---|
| `geometry-hac_binding.ads/.adb` | native adapter: one callback per bound subprogram, plus registration |
| `geometry_hac.ads` | HAC-side declarations, `with Import => True` |
| `geometry.hac-bindings.json` | binding manifest (gadget; see [roadmap](../roadmap.md)) |

Every file carries the generation header ([S002]), and regenerating
from the same input produces identical files ([S001]).

## Naming rules

- Ada identifiers retain their names on the HAC side: `New_Point` stays
  `New_Point`. There is no external-name override mechanism: the
  exposed name is the Ada name — rename in the package, not in a
  directive ([S005]).
- Name collisions are reported, never resolved by inventing suffixes:
  overloaded exported names ([B001], `HACB0001`), duplicate HAC-visible
  operation names, and names reserved by the generated runtime support.

## Boundary range and representation checks

Generated callbacks check every value that crosses the boundary: an
integer received from HAC is validated against the native subtype
range, an out-of-range or unrepresentable value raises a defined
boundary error, not a silent narrowing ([S003], [S007] class 2, and
[C002](C002_boundary_errors.md)).

## The reference test shape

Every scenario of this page follows the same end-to-end shape: the
Given are Ada files — the API package, whose body prints the parameters
it receives, so that bbt observes from the printed output that a call
actually happened, in both directions; the When is the hac-bindgen
invocation; the Then compiles the witness application with GNAT, runs
the HAC script through the real HAC compiler and VM, and compares the
observed output, which bbt owns.

Reference scenario — *a parameterless procedure is bound and called*:
the script calls `Ping`; the native body prints
`native: ping received`; the script prints `hac: ping returned` after
the call returns; bbt expects the two lines in that order. The input
API:

```ada
package Api is
   procedure Ping;
end Api;
```

the HAC script:

```ada
procedure Script is
   procedure Ping with Import => True;
begin
   Ping;
   HAT.Put_Line ("hac: ping returned");
end Script;
```

## Planned scenarios

Each row is a behavior to implement; the identifier is the stable
scenario key, referenced from the code and the cross-reference table.

| ID | Scenario | Exercised behavior |
|---|---|---|
| A002-01 | a parameterless procedure is bound and called | registration, callback call, import declaration — the reference shape above |
| A002-02 | an integer function round-trips | both conversion directions ([S003]): the API body prints the integer it receives, the script prints the result it receives back |
| A002-03 | a floating-point function round-trips | same shape; the precision reduction, if any, is documented in the manifest ([S003]) |
| A002-04 | a Boolean result is transported | the HAC representation (Integer or enum) is explicit in the generated declarations ([S003]) |
| A002-05 | a string parameter crosses the boundary | string ownership and lifetime follow the actual `HAC_Sys.Interfacing` representation ([S003]) |
| A002-06 | `out` and `in out` parameters are bound | the callback writes the modified value back into the argument slot; deferred until the `in` profile works end to end |
| A002-07 | regeneration is byte-identical | [S001]: two `generate` runs on the same input produce identical files |
| A002-08 | every generated file carries the version header | [S002]: each generated file starts with the generation header |
| A002-09 | adding one operation needs no handwritten glue | [S009]: one new façade subprogram, one regeneration, one new script line — no adapter edit |
| A002-10 | an out-of-range integer is a boundary error | the script sends an Integer outside the native subtype range: defined boundary error at run time, no silent narrowing ([S003], [C002]) |
| A002-11 | bound operations keep their Ada names | the HAC-visible name equals the Ada name; a deliberate rename is done in the exposed package ([S005]) |
| A002-12 | a name collision is reported, not mangled | duplicate or reserved names produce warnings; no automatic suffix ([B001]) |
