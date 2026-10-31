# A005 — Rich enumerations at the boundary <!-- omit from toc -->

The scalar profile of [A002](A002_facade_generation.md) pins the basic
enumeration boundary: an identifier-literal enumeration is mirrored
exactly on the HAC side and converted through `T'Pos` / `T'Val`. This
page owns the two wider shapes, settled by running HAC 0.45.0
(2026-10-31 exploration): enumerations with **representation
clauses**, which bind unchanged, and enumerations with
**character literals**, which HAC cannot even parse and which warn
out with [HACB0017](B001_non_bindable_constructs.md#the-catalogue).

## Contents <!-- omit from toc -->

- [Representation clauses are out of the model](#representation-clauses-are-out-of-the-model)
- [Character-literal enumerations are not bindable](#character-literal-enumerations-are-not-bindable)
- [Enumeration results](#enumeration-results)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: an enumeration with a representation clause still binds](#scenario-an-enumeration-with-a-representation-clause-still-binds)
  - [Scenario: a function returns an enumeration value](#scenario-a-function-returns-an-enumeration-value)
  - [Scenario: a character-literal enumeration is warned out](#scenario-a-character-literal-enumeration-is-warned-out)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)

## Representation clauses are out of the model

The backend never reports a representation clause: Libadalang does
not expose `for T use (...)` or `for T'Size use ...` as API
declarations, they produce no dump line and no `unhandled` line, and
the dump grammar of [A003](A003_interchange_dump.md) keeps it that
way (documented status, agreed 2026-10-31). This is boundary-neutral:
the generated conversions use `'Pos` and `'Val`, which are positional
and ignore the representation; the native representation never
crosses the boundary, so no fact is lost or silently converted
([S003]).

Consequence for the mirror: the HAC-side mirror repeats the type
declaration only. HAC would reject a clause anyway (verified: the
clause syntax is a parse error in HAC 0.45.0).

## Character-literal enumerations are not bindable

HAC 0.45.0 rejects `type Digit is ('0', '1', ...)` with a parse error
on every literal (verified by execution). The classification,
[HACB0017](B001_non_bindable_constructs.md#the-catalogue):

- The type declaration warns `HACB0017` at its own location.
- Every operation taking or returning such a type counts as not
  bound; each offending parameter or result warns `HACB0017` at its
  own location, like the other per-profile warnings of [B001]. The
  rule follows the root of the subtype chain: a subtype of a
  character-literal enumeration is warned as well.
- No mirror of the type is emitted, and no generated file mentions it
  ([S006], [S009]): emitting what HAC cannot compile would produce a
  broken façade.
- The exit status stays `0` — a warning, not a failure ([B001]).

Detection needs no new dump fact: the `enum` dump line already
carries the literals verbatim (`literals '0' '1' 'A' 'B`).

## Enumeration results

A bound function may return an enumeration value: the result crosses
native→HAC through `To_HAC_Any_Enum` into `Data (1)`, and the
HAC-side wrapper returns it as its mirrored enumeration type. The
script compares the result with a literal and gets real enumeration
semantics (`=`, `'Succ`, case statements — all verified working in
HAC 0.45.0).

One emission rule from the exploration: generated HAC-side code never
uses an attribute chain (`T'Pos (X)'Image`), which HAC rejects — the
generated bodies express the same facts without it ([S004]).

## Executable scenarios

The end-to-end scenarios use the harness of
[A002](A002_facade_generation.md): files in `run/`, witness built with
the e2e project, script run by the static witness main. All scenarios
run from `tests/`.

| Scenario | Behavior |
|---|---|
| A005-01 | an enumeration with a representation clause still binds |
| A005-02 | a function returns an enumeration value |
| A005-03 | a character-literal enumeration is warned out |

### Scenario: an enumeration with a representation clause still binds

- Given the new directory `run`
- Given the new file `run/traffic_api.ads` containing
  ```ada
  package Traffic_Api is
     type Light is (Red, Amber, Green);
     for Light use (Red => 0, Amber => 3, Green => 7);
     for Light'Size use 8;
     procedure Set (L : in Light);
  end Traffic_Api;
  ```
- Given the new file `run/traffic_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Traffic_Api is
     procedure Set (L : in Light) is
     begin
        Ada.Text_IO.Put_Line ("native: light set to"
                              & Light'Image (L));
     end Set;
  end Traffic_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/traffic_api.ads --output-dir run --hac-package HAC_Traffic_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Traffic_Api_Native;
  package Witness_Binding renames Traffic_Api_Native;
  ```
- Given the new file `run/traffic_script.adb` containing
  ```ada
  with HAC_Traffic_Api;
  procedure Traffic_Script is
  begin
     HAC_Traffic_Api.Set (HAC_Traffic_Api.Amber);
  end Traffic_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/traffic_script.adb`
- Then I get
  ```text
  native: light set to AMBER
  E2E: script completed.
  ```
- And the file `run/hac_traffic_api.ads` contains `type Light is (Red, Amber, Green);`

### Scenario: a function returns an enumeration value

- Given the new directory `run`
- Given the new file `run/next_api.ads` containing
  ```ada
  package Next_Api is
     type Light is (Red, Amber, Green);
     function Next (L : in Light) return Light;
  end Next_Api;
  ```
- Given the new file `run/next_api.adb` containing
  ```ada
  package body Next_Api is
     function Next (L : in Light) return Light is
     begin
        if L = Light'Last then
           return Light'First;
        else
           return Light'Succ (L);
        end if;
     end Next;
  end Next_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/next_api.ads --output-dir run --hac-package HAC_Next_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with Next_Api_Native;
  package Witness_Binding renames Next_Api_Native;
  ```
- Given the new file `run/next_script.adb` containing
  ```ada
  with HAC_Next_Api;
  with HAT;
  procedure Next_Script is
     L : HAC_Next_Api.Light := HAC_Next_Api.Next (HAC_Next_Api.Red);
  begin
     if L = HAC_Next_Api.Amber then
        HAT.Put_Line ("script: next is Amber");
     else
        HAT.Put_Line ("script: MISMATCH");
     end if;
  end Next_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/next_script.adb`
- Then I get
  ```text
  script: next is Amber
  E2E: script completed.
  ```

### Scenario: a character-literal enumeration is warned out

- Given the new directory `run`
- Given the new file `run/hex_api.ads` containing
  ```ada
  package Hex_Api is
     type Digit is ('0', '1', '2');
     procedure Use_Digit (D : in Digit);
  end Hex_Api;
  ```
- When I successfully run `../bin/hac-bindgen check run/hex_api.ads`
- Then the exit code is `0`
- And the output contains `warning HACB0017`
- And the output contains `is not bound: HAC only accepts identifier literals`
- And the output contains `0 operations bound, 1 not bound (see warnings)`

## Verification beyond bbt

- Unit tests: not applicable — the bbt scenarios are the test suite.
- SPARK / proof: not applicable.
- Other: the HAC facts (clause syntax rejected, character literals
  rejected, enum attributes and comparisons working) were verified by
  execution of the HAC 0.45.0 interpreter during the 2026-10-31
  exploration; the e2e scenarios re-prove the binding side.

## Design implications

Representation clauses out of the model is the documented option (a)
of the 2026-10-31 arbitration: they are not API declarations, and the
positional conversion makes them boundary-neutral. [HACB0017] keeps
the catalogue's stability contract of
[B001](B001_non_bindable_constructs.md): a new stable key, no
renumbering. The attribute-chain rule is a generated-code quality
rule ([S004]) learned from HAC's parser.
