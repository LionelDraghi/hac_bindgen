# Roadmap

Prioritised development plan. The manifest separates the essential from
the gadgets; this plan commits the order. Details remain in the linked
sources; feature IDs refer to [`specifications.md`](specifications.md).

## M1 — Foundations (essential)

Project skeleton, CLI, executable-documentation harness.

- [x] Repository created from [ada-project-template](https://github.com/LionelDraghi/ada-project-template)
- [x] Specification structure: `specifications.md` + numbered `features/`
- [ ] CLI skeleton: `--version`, `--help`, `check` stub, usage errors → [A001], [C001]
- [ ] First green bbt run (`make check`)

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
- [ ] Analysis backend #1: parse an Ada package specification into the
      model. Backend choice recorded in
      `docs/dev/design_discussions.md` (Libadalang vs a lightweight
      reader; the comparison with a second backend is a gadget)
- [ ] Licensing of the selected backend recorded before the decision
      (concern indexed in `docs/dev/concerns.md`)
- [ ] Traversal contract: every public declaration classified bindable
      or not ([S006])

## M4 — Generation (essential, the product)

- [ ] Native adapter generator: callbacks, conversions, registration
- [ ] HAC declaration generator: `with Import => True` stubs
- [ ] Witness application in `tests/`, wired into bbt scenarios
- [ ] End-to-end: [A002-01] through [A002-05] green ([S008], [S009])
- [ ] Determinism and version headers: [A002-07], [A002-08] ([S001], [S002])

## M5 — Warnings catalogue (essential)

- [ ] Warning format and stable identifiers ([B001])
- [ ] First catalogue entries: overloads, access, private/tagged,
      composites, `out`/`in out` ([B001-01] .. [B001-04])
- [ ] Summary output: bound / not bound counts

## M6 — Wider profile (essential, incremental)

- [ ] Handles and enumerations ([S003], new `Annn` pages)
- [ ] Strings end to end (ownership demonstrated, not assumed)
- [ ] `out`/`in out` copy-back ([A002-06], [HACB0008] retired)
- [ ] Several bound packages registering into one HAC environment
      (name collisions included)
- [ ] Repeated script execution in the same witness application,
      if the HAC VM supports it

## Gadgets (later, on demand)

- JSON binding manifest ([A002] mentions it; generation is trivial
  once the model exists, its *uses* are the gadget)
- `verify` command (byte-identical regeneration check)
- Diagnostic formats: gcc-style, SARIF
- Second analysis backend and its recorded comparison
- CI workflow, AppImage, Alire publication
- Helper handle-registry library for generated façades
