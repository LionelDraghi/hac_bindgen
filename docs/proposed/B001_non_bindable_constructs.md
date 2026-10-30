# B001 — Non-bindable constructs: warnings <!-- omit from toc -->

hac-bindgen traverses the supplied API and binds what it can; what it
cannot bind triggers a warning, never a package rejection, and never a
silent drop ([S006]). This page owns the catalogue of non-bindable
constructs and the warning format.

Warning format:

```text
source.ads:LINE:COL: warning HACBxxxx: <construct> is not bound: <reason>
```

The warning carries a stable diagnostic identifier (`HACBxxxx`), the
precise source location, and a short reason. Warnings go to the
standard error; the standard output keeps the traversal summary:

```text
Geometry: 7 operations bound, 2 not bound (see warnings)
```

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
| HACB0005 | record, discriminated record, anonymous array or record | composite mapping deferred; explicit profile first |
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

## Planned scenarios

Each row is a behavior to implement; the identifier is the stable
scenario key. The scenarios move to bbt form in this page as the
traversal and the warnings land.

| ID | Scenario | Exercised behavior |
|---|---|---|
| B001-01 | an overloading is warned out, the rest is generated | a package exposes `Create` twice: warning `HACB0001` on one, the other bound, the summary reports both counts |
| B001-02 | the generated binding covers the bindable part only | a mixed package: the generated adapter and declarations contain only the bound subprograms ([S006], [S009]) |
| B001-03 | `check` reports the same classification | `check` prints the same warnings and summary as `generate`, and writes no file |
| B001-04 | every warning is actionable | each warning line points at the source location of the offending declaration |
| B001-05 | pointer-ish declarations are all warned out | access types, access parameters, `System.Address` parameters: `HACB0003`, `HACB0014` — the package still binds its scalars |
| B001-06 | composite and object-boundary declarations are warned out | records, arrays, tagged/private/controlled, tasks: `HACB0004`, `HACB0005`, `HACB0006`, `HACB0015` |
| B001-07 | nothing is silently dropped | a package full of non-bindable declarations generates no binding but every declaration is accounted for in the summary ([S006]) |
