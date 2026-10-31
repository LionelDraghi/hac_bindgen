# Roadmap <!-- omit from toc -->

Prioritised development plan. The manifest separates the essential from
the gadgets; this plan commits the order. Details remain in the linked
sources; feature IDs refer to [`specifications.md`](specifications.md).

## M1 — Foundations (essential)

Project skeleton, CLI, executable-documentation harness.

- [x] Repository created from [ada-project-template](https://github.com/LionelDraghi/ada-project-template)
- [x] Specification structure: `specifications.md` + numbered `features/`
- [x] CLI skeleton: `--version`, `--help`, `check` stub, usage errors → [A001], [C001]
- [x] First green bbt run (`make check`)

## M2 — HAC interfacing evidence (essential)

Stage 0: pin the real callback surface before
generating anything. The reference is
`https://github.com/zertovitch/hac` (HAC 0.45.0); the findings land
in `docs/dev/hac_interfacing_notes.md` and drive the generated-code
templates.

- [x] Document the exact callback mechanism: `Exported_Procedure`
      (procedure with `HAC_Element_Array`), registration
      (`HAC_Sys.Interfacing.Register`), functions emulated through a
      result slot, argument and result representations (Integer,
      Long_Float, String, generic integer/enum/float), error reporting
      (`HAC_Type_Error`), and the HAC-side
      `with Import => True` declarations
- [x] First manually written witness application that embeds HAC and
      runs a script through generated-style callbacks

## M3 — Binding model and analysis (essential)

- [x] Binding model: the parser-independent representation of all
      public declarations, subprogram profiles, types, and source
      locations — `Hac_Bindgen.Model`
- [x] Analysis backend #1 selected and isolated: Libadalang in a
      dedicated GNAT 15.x crate emitting the format-1 interchange dump
      ([A003]; decision in `docs/dev/design_discussions.md`)
- [x] Analysis backend #1: parse an Ada package specification into the
      model with Libadalang (selected 2026-10-29, see
      `docs/dev/design_discussions.md`); the comparison with a second
      backend is a gadget
- [x] Licensing of the selected backend recorded before the release
      (no blocking incompatibility, decision of 2026-10-31 in
      `docs/dev/design_discussions.md`)
- [x] Traversal contract: every public declaration classified bindable
      or not ([S006], [B001])

## M4 — Generation (essential, the product)

Release trigger: version 0.1.0 ships when the first complete binding
is generated end to end.

- [x] Native adapter generator: callbacks, conversions, registration
- [x] HAC declaration generator: `with Import => True` stubs
- [x] Witness application in `tests/`, wired into bbt scenarios
- [x] End-to-end: [A002-01] through [A002-05] green ([S008], [S009])
- [x] Determinism and version headers: [A002-07], [A002-08] ([S001], [S002])

## M5 — Warnings catalogue (essential)

- [x] Warning format and stable identifiers ([B001])
- [x] First catalogue entries: overloads, access, private/tagged,
      composites, `out`/`in out` ([B001-01] .. [B001-04]; B001-02 is
      the [A002-05] scenario, B001-03 is pinned by the identical
      warning and summary formats of `check` and `generate`)
- [x] Summary output: bound / not bound counts

## M6 — Wider profile (essential, incremental)

- [x] Handles and enumerations ([S003], new `Annn` pages — [A004],
      [A005])
- [x] Strings end to end, copy both ways ([A006])
- [x] `out`/`in out` copy-back ([A002-06], [HACB0008] narrowed to
      functions and `out` of a handleable type)
- [x] Several bound packages registering into one HAC environment
      (name collisions included) ([A007])
- [x] Repeated script execution in the same witness application,
      if the HAC VM supports it ([A008]; supported)

## M7 — Composite boundary values (essential)

Targeted use case: generate the TopoScript bindings of
[topoproof](https://github.com/LionelDraghi/topoproof)'s geometry
domains (`tools/topocli`), whose script-facing operations exchange
records (`Point_3D`, `Vector_3D`) — all warned out today
([HACB0005]).

- [ ] Record boundary values ([HACB0005] narrowed): a record type is
      mirrored HAC-side and marshalled component-wise into consecutive
      `Data` slots, the `Size_of` layout of the M2 evidence computed
      recursively for nested records
- [ ] Record copy-back: `out` / `in out` record parameters written
      back like scalars, the native subtype checks applying on the way
      back
- [ ] First real-world binding: the TopoScript geometry domain of
      topoproof generated end to end — records, enumerations and
      scalars in one binding, exercised by the topocli witness
      application

## Gadgets (later, on demand)

- JSON binding manifest ([A002] mentions it; generation is trivial
  once the model exists, its *uses* are the gadget)
- `verify` command (byte-identical regeneration check)
- Diagnostic formats: gcc-style, SARIF
- Second analysis backend and its recorded comparison
- CI workflow, AppImage, Alire publication
- Helper handle-registry library for generated façades
