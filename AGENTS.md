# Project instructions

The shared instructions in [`ada-project-template/AGENTS.md`](https://github.com/LionelDraghi/ada-project-template/blob/main/AGENTS.md) apply in full.

**Read them immediately, before any other reading or any action.**

## Project identity

- Name: `hac_bindgen`
- Purpose: binding generator that exposes a native Ada API to the HAC
  Ada interpreter: it traverses the supplied package specification(s),
  generates the scripting façade glue (native adapter, HAC declarations,
  registration), and warns on every public subprogram it cannot bind.
- Primary language: Ada

## Enabled capabilities

| Capability | Enabled | Project parameter, if any |
|---|---:|---|
| bbt executable specifications | yes | `make check`; scenarios live in `docs/features/` and run through the top-level Makefile |
| Unit tests | no | the bbt scenarios are the test suite |
| SPARK analysis | no | N/A |
| Formal proof | no | N/A |
| Static analysis / metrics | no | N/A |
| Alire release | yes | planned; crate `hac_bindgen`, not published yet |
| Platform packages | no | N/A |

## Project commands

- Build: `make build` (Alire build of the `hac_bindgen` crate)
- Quick validation: `make build`
- Full validation: `make check` (build + bbt)
- Generate reports: N/A

## Project-specific paths or release parameters

- Tool name: `hac-bindgen` (executable), crate name: `hac_bindgen`
- HAC reference for the interfacing evidence: HAC 0.45.0, official repository
  https://github.com/zertovitch/hac; the in-tree dependency comes from the
  Alire community index.
- Executable documentation: `docs/specifications.md` indexes the
  `docs/features/` pages; feature files follow the `Annn`/`Bnnn`/`Cnnn`
  numbering scheme (see `documentation_structure.md` in the reference
  repository).

## Exceptions

None.
