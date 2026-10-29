# HAC interfacing notes — M2 working document

Stage 0 of the original manifesto: pin the real callback surface before
generating anything. Reference checkout:
`~/Private/hac-lab/hac_0.45.0_b9083b3c` (HAC 0.45.0), demos
`demo/data_exchange/` and `demo/data_exchange_simple/`. Everything
below must be **verified against the actual implementation**, not
assumed — this file records the evidence and the answers.

## What is already established (from the 0.45.0 sources)

- Callback type: `HAC_Sys.Interfacing.Exported_Procedure` is
  `access procedure (Data : in out HAC_Element_Array)`.
- Registration: `HAC_Sys.Interfacing.Register (BD, Callback, Name)`,
  possible at any time (before compilation, after, even at run time).
- Conversions native → HAC: `To_HAC` for `Integer`, `Long_Float`,
  `String`; generics `To_HAC_Any_Integer` (range types),
  `To_HAC_Any_Enum`, `To_HAC_Any_Float` (digits types).
- Conversions HAC → native: `To_Native` for the same direct types,
  same generics.
- Error surface: `HAC_Sys.Interfacing.HAC_Type_Error`.
- HAC side: native operations are declared in the script with
  `with Import => True` (see `demo/data_exchange/exchange_hac_side.adb`).
- VM variables: `Get_VM_Variable` / `Set_VM_Variable`, string valued,
  readable from HAC through `HAT.Get_VM_Variable`.

## To verify and record (the Stage 0 checklist)

- [ ] Functions: the demo emulates them through a result slot in the
      `HAC_Element_Array` — confirm the exact convention (slot index,
      direction, in the demo's HAC side) and record it.
- [ ] `with Import => True` inside a package specification (not only
      in nested procedure declarations): does the HAC compiler accept
      it? This decides the shape of the generated HAC declaration
      package (`Geometry_Scripting_HAC` of the original manifesto).
- [ ] Boolean representation: no direct `To_HAC (Boolean)` — test the
      generic enum route and the Integer route; pick and record.
- [ ] Exact integer and floating-point representations of the HAC VM
      (range, precision), and what a native subtype range check needs.
- [ ] Strings: representation across the boundary, ownership, lifetime
      of the value inside a callback, encoding.
- [ ] Error reporting: what happens on a raised `HAC_Type_Error` and on
      an arbitrary native exception inside a callback — message, HAC
      source location, script termination behavior.
- [ ] Callback state ownership: global, per `Build_Data`, or per VM?
      Re-entrancy and concurrency assumptions; can a callback invoke
      HAC recursively?
- [ ] Several packages registering into one environment: name
      collisions? Package-qualified names?
- [ ] Compiler and VM lifetime: what must stay alive for the callbacks
      to remain callable.

The answers feed the generated-code templates (M4) and the boundary
error scenarios ([C002]).

## Open analysis questions (from M3, recorded here until the design discussion)

- How much semantic resolution does each candidate backend (Kazakov's
  Ada Syntax Analyzer, Libadalang) provide for the profile: package
  and subprogram identification, parameter modes, result types, local
  subtype chains, predefined-type recognition, source locations?
- Does either backend need project configuration for a single-file
  specification?
- Which backend gives reliable type resolution for the smallest
  dependency cost — see the evaluation criteria in the original
  manifesto (§8), kept there rather than duplicated here.
