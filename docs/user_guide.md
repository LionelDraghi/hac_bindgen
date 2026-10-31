# User guide <!-- omit from toc -->

How to use `hac-bindgen` in your project, and what it does to your
API. The error codes the tool emits have their own index: the
[HACBxxxx catalogue](features/B001_non_bindable_constructs.md#the-catalogue).

## Getting it done

For a package specification `geometry.ads`, one command generates the
facade:

```sh
hac-bindgen generate geometry.ads --output-dir generated --hac-package HAC_Geometry
```

What hac-bindgen writes, and what everyone does with it:

```mermaid
---
config:
  theme: base
---
flowchart TB
    SRC["geometry.ads<br/>(your API, plain Ada)"] --> BINDGEN["hac-bindgen generate"]
    BINDGEN --> HACPKG["generated/hac_geometry.ads, .adb<br/>the script-facing package"]
    BINDGEN --> NATPKG["generated/geometry_native.ads, .adb<br/>the native adapter"]
    BINDGEN --> OUT["standard output:<br/>warnings + bound / not bound summary"]
    NATPKG -- "Register_All (BD)" --> APP["your application,<br/>embedding HAC"]
    SCRIPT["your HAC script<br/>with HAC_Geometry;"] --> APP
    APP --> RUN["GNAT compiles the native side;<br/>HAC interprets the script"]
```

| Step | Who | What |
|---|---|---|
| 1. Generate | you | `hac-bindgen generate SOURCE... [--output-dir DIR] [--hac-package NAME]` |
| 2. Compile | GNAT | the generated `*_native.ads/.adb` (and the API body) join your GNAT project; call `<Pkg>_Native.Register_All (BD)` from your embedding main — see the complete example in [tests/e2e/witness_main.adb](../tests/e2e/witness_main.adb) |
| 3. Run | HAC | your script `with`s the HAC-side package and calls the bound operations like any Ada package |

The generated file set, for a package `Geometry`:

| File | Side | Content |
|---|---|---|
| `geometry.ads` / `.adb` (or `hac_geometry.ads` / `.adb` with `--hac-package`) | HAC | the package the script `with`es: bound declarations, type mirrors, private imports |
| `geometry_native.ads` / `.adb` | native | `Register_All (BD)`, one callback per bound operation, the conversions, the handle registries |

`--hac-package` renames the HAC-side package so the generated files
can live in your source tree without clashing with the real
`geometry.ads` in GNAT's path. `hac-bindgen check SOURCE...` runs the
analysis and the classification only — same warnings, same summary,
no files written.

## What hac-bindgen does to your API

The analysis pipeline is: **analyze** (Libadalang backend, isolated in
its own crate) → **classify** (bindable or not) → **generate**. One
traversal feeds both `check` and `generate` ([S006]).

Bound today (the scalar and handle profiles):

- Procedures and functions with `in` parameters; a bound function is
  a real HAC function for the script.
- `out` and `in out` parameters of procedures with scalar types: the
  native results are written back into the script's variables, and
  the native range checks apply on the way back too.
- Scalars: `Integer`, `Long_Float`, `Boolean`, user-defined range
  types and their subtypes, and
  enumerations — mirrored exactly on the HAC side and converted by
  position, so representation clauses are harmless.
- Private and tagged private types: bound as **integer handles** —
  the script holds an opaque number, the generated adapter resolves
  it to the object it owns. A generated `Drop_<T>` operation releases
  the registry entry; a dropped or never-issued handle stops the
  script with a defined boundary error.

Warned out, never silently dropped ([B001]): each non-bindable
declaration gets a stable `HACBxxxx` identifier, the source location,
and a reason, on standard output, followed by a per-package bound /
not bound summary. Warnings are diagnostics: the exit status stays
`0`. The full catalogue — what each code means and why — is the
[HACBxxxx index](features/B001_non_bindable_constructs.md#the-catalogue).

Not yet (planned, [docs/roadmap.md](roadmap.md)): strings end to end,
several bound packages in one run, repeated script execution.

The conversion rule everywhere: **no silent conversion** ([S003]) —
a value that cannot cross safely is warned out at generation time or
reports a defined error at run time, never a default value.
