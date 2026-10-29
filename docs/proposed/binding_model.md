# M3 — Parser-independent binding model

Status: Accepted
Source: [M3 in the roadmap](../roadmap.md)

## Need

The analyser and later generators need a shared representation of a
package's public API. If parser-specific nodes leak past analysis,
changing or testing an analysis backend becomes coupled to code
generation.

## Intended outcome

Define `Hac_Bindgen.Model` as the parser-independent representation of
the declarations hac-bindgen must account for. It must preserve enough
information for binding decisions, source diagnostics, and generation,
without requiring downstream code to depend on a parser library.

## Scope

- Package identity and every public declaration found in its
  specification, including declarations that are not subprograms and
  will receive a warning.
- Procedure/function distinction, parameter order and modes, parameter
  and result type references.
- Declaration identity and source location for actionable diagnostics.
- A separate traversal result that associates every public declaration
  with either a bindable classification or a stable warning identifier
  and reason ([S006], [B001]).
- Explicit representation of types or declarations the selected
  backend cannot resolve; they must not disappear from the model.

## Non-goals

- Choosing or wrapping the Ada analysis backend; that choice belongs in
  [design discussions](../dev/design_discussions.md).
- Generating HAC declarations, native adapters, manifests, or CLI
  diagnostics.
- Deciding which API shapes are bindable; the existing feature
  specifications and warning catalogue own that behavior.
- Modelling Ada declarations outside the supplied package's public API.

## Acceptance criteria

- `Hac_Bindgen.Model` contains no dependency on the selected parser's
  public types or allocated parser nodes.
- All public declarations retain source order, source spelling, a
  canonical name, and a stable model identity.
- Each subprogram exposes its name, kind, ordered parameters, modes,
  parameter type references, optional function result type, and source
  location.
- Each declaration is represented exactly once in the separate
  traversal result and is explicitly classified bindable or not
  bindable; a warning includes its stable identifier, location, and
  reason.
- Unknown or unresolved type information is explicit and cannot be
  mistaken for a supported scalar type.
- A model fixture can be constructed without invoking or linking an
  analysis backend.

## Specification

The model is the boundary between analysis and all later passes. It
represents the public API, not parser syntax trees. Names and type
references carry source spelling for generated output and diagnostics,
alongside a canonical identity for Ada's case-insensitive name
matching. Source locations store the specification's file path and the
declaration's starting line and column.

Subprogram profiles preserve parameter declaration order and modes.
Functions retain their result type separately from parameters. Type
references preserve the declared name and resolution state. When
available, they carry the resolved type identity and category, plus a
subtype chain ordered from the referenced subtype to its root type.
Partial resolution remains explicit.

Analysis classification is stored separately and refers to a model
declaration by its stable identity. It does not erase the original
declaration or profile. Non-bindable results carry the stable warning
identifier, source location, and reason. Validation rejects missing,
duplicate, or unknown declaration references. Parser diagnostics that
prevent a package model from being constructed remain analysis errors,
not traversal warnings ([C001]).

## Executable scenarios

No bbt scenario applies yet: the model is an internal Ada data
contract, not an observable CLI behavior. Verify its construction and
invariants with focused Ada tests or fixtures when the model is
implemented; end-to-end classification scenarios belong to [B001].

## Verification beyond bbt

- Unit tests: the project does not enable a separate unit-test
  framework. Add focused model construction checks alongside the first
  backend fixtures, without introducing a second test framework.
- SPARK / proof: not applicable; SPARK and proof are disabled.
- Other: `make build` and `make check`; backend-produced fixtures must
  satisfy the same model invariants.

## Design implications

The model must not make parser-specific identities, token types, or
source buffers part of the downstream API. Resolve the backend
licensing concern before selecting the parser. Track the backend and
type-resolution decision in [design discussions](../dev/design_discussions.md).

## Decisions

- Source locations store the file path, line, and column.
- Type references retain resolution state and the subtype chain when
  available.
- Classifications are a separate analysis result referring to model
  declaration identities.

## Finalization target

The durable contract is recorded in `docs/dev/design_discussions.md`
and implemented in `Hac_Bindgen.Model`. The roadmap entry is complete
once the model builds and validates declaration/result consistency.
