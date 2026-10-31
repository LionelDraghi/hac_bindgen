# A003 — Analysis backend interchange dump <!-- omit from toc -->

The analysis backend lives in its own Alire crate
(`tools/libadalang_backend`, GNAT 15.x + Libadalang 26.0.0) while the
main generator stays on GNAT 16 — see the backend isolation decision in
[design discussions](../dev/design_discussions.md#analysis-backend-evaluation).
The dump the backend writes is the only coupling between the two: the
main crate builds `Hac_Bindgen.Model` from it and never links
Libadalang.

## Contents <!-- omit from toc -->

- [The dump contract](#the-dump-contract)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: dump identifies itself](#scenario-dump-identifies-itself)
  - [Scenario: subprogram profiles with explicit modes](#scenario-subprogram-profiles-with-explicit-modes)
  - [Scenario: a parameterless subprogram is dumped like any other](#scenario-a-parameterless-subprogram-is-dumped-like-any-other)
  - [Scenario: type references resolve to their declaration](#scenario-type-references-resolve-to-their-declaration)
  - [Scenario: enumeration literals in declaration order](#scenario-enumeration-literals-in-declaration-order)
  - [Scenario: static values are evaluated](#scenario-static-values-are-evaluated)
  - [Scenario: an index constraint is dumped](#scenario-an-index-constraint-is-dumped)
  - [Scenario: private part is separated from the public API](#scenario-private-part-is-separated-from-the-public-api)
  - [Scenario: declarations that are not API declarations are skipped](#scenario-declarations-that-are-not-api-declarations-are-skipped)
  - [Scenario: unusual declarations are reported, not dropped](#scenario-unusual-declarations-are-reported-not-dropped)
  - [Scenario: dump is deterministic](#scenario-dump-is-deterministic)
  - [Scenario: parse error produces no dump](#scenario-parse-error-produces-no-dump)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)

## The dump contract

The dump is UTF-8 text, one logical fact per line, indented by two
spaces per nesting level. Every line is a token sequence separated by
single spaces. It is deterministic ([S001]): the same input produces
byte-identical output, with no absolute path and no
environment-dependent content.

Header and framing:

```text
hac-bindgen-backend <tool-version> format 1
package <Package_Name> loc <file>:<line>:<col>
public
  <declaration lines>
private
  <declaration lines>
end <Package_Name>
```

- The first line is always the header: tool name, tool version, and
  `format <n>`. A reader must reject a format number it does not
  implement.
- The `private` section is omitted when the package has no private
  part. The consumer decides bindability: only `public` declarations
  are candidates ([S006]).
- Format 1 is frozen since the main-crate reader landed
  (`Hac_Bindgen.Dump_Reader`); any change now requires a format bump.

Declaration lines start with a kind keyword:

```text
  subtype <Name> loc <file>:<line>:<col> base <Type_Mark> resolved <Identity> [constraint <Low> .. <High>]
  enum <Name> loc <file>:<line>:<col> literals <Lit_1> <Lit_2> ...
  type <Name> loc <file>:<line>:<col> definition <Source_Spelling>
  procedure <Name> loc <file>:<line>:<col>
  function <Name> loc <file>:<line>:<col>
  constant <Name> loc <file>:<line>:<col> type <Type_Mark> resolved <Identity> [value <Image>]
  variable <Name> loc <file>:<line>:<col> type <Type_Mark> resolved <Identity> [value <Image>]
  unhandled <Parser_Kind> loc <file>:<line>:<col>
```

Subprogram profile lines are indented one level under their subprogram
and appear in parameter declaration order:

```text
    param <Name> loc <file>:<line>:<col> mode <in|in out|out> type <Type_Mark> resolved <Identity>
    returns <Type_Mark> resolved <Identity>
```

- `loc` designates the defining identifier — the package name, the
  declared identifier, or the parameter identifier — 1-based line and
  column; `<file>` is the path exactly as supplied on the command line
  (relative stays relative).
- `mode` is always explicit, including the default `in`.
- `type <Type_Mark>` preserves the source spelling of the type mark.
  An object declaration without a type mark (anonymous number
  declaration) is reported with the type mark `<anonymous>` and
  `resolved unresolved`.
- `resolved <Identity>` is one of:
  - `standard.<Name>` for a predefined entity;
  - `<file>:<line>:<col>` pointing at the defining `loc` of an entity
    declared in this dump;
  - `unresolved` — never omitted and never silently mapped to a
    supported type ([S003], parser-independent model contract).
- `constraint` is present for statically evaluable range constraints,
  with the bounds as decimal integers; otherwise
  `constraint (dynamic)`.
- `value` is present when the initializer is statically evaluable
  (format 1 covers integers only); otherwise `value (dynamic)`; it is
  absent when there is no initializer.
- `definition <Source_Spelling>` preserves the source text of the
  type definition with runs of whitespace collapsed to single spaces,
  so a declaration stays on one dump line; it is empty for an
  incomplete type declaration.
- `unhandled` lines: declarations that are not API declarations
  (pragmas, use clauses) produce no dump line at all; a *declaration*
  whose kind is not covered by the format is reported with the
  parser's kind name rather than dropped ([S006], model contract). It
  is never emitted for the kinds listed above.

Failure mode: when the input cannot be parsed, no dump is produced —
the backend exits nonzero and writes diagnostics on standard error.
Analysis errors are not dump content.

New Ada constructs extend the format with a version bump instead of
changing existing lines; multi-package and generic specifications are
not covered by format 1.

## Executable scenarios

The command path follows the project convention: bbt runs from
`tests/` ([Makefile](../../Makefile)), so the backend binary is at
`../tools/libadalang_backend/bin/hac_bindgen_backend`, built by
`make check` before the scenarios run.

Each scenario compares the **whole dump**: the dump itself is the
contract under test, so the expected output is written in full rather
than cherry-picked with `contains` checks. The fixtures are written
with the two-space list indentation kept on every line — the recorded
column values include it; re-indenting a fixture means re-recording
its expected dump.

### Scenario: dump identifies itself

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     procedure Mutate (X : in Integer);
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    procedure Mutate loc probe_fixture.ads:2:16
      param X loc probe_fixture.ads:2:24 mode in type Integer resolved standard.Integer
  end Probe_Fixture
  ```

### Scenario: subprogram profiles with explicit modes

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     procedure Mutate (X : in Integer; Y : in out Integer; Z : out Boolean);
     function Add (Left, Right : Integer) return Integer;
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    procedure Mutate loc probe_fixture.ads:2:16
      param X loc probe_fixture.ads:2:24 mode in type Integer resolved standard.Integer
      param Y loc probe_fixture.ads:2:40 mode in out type Integer resolved standard.Integer
      param Z loc probe_fixture.ads:2:60 mode out type Boolean resolved standard.Boolean
    function Add loc probe_fixture.ads:3:15
      param Left loc probe_fixture.ads:3:20 mode in type Integer resolved standard.Integer
      param Right loc probe_fixture.ads:3:26 mode in type Integer resolved standard.Integer
      returns Integer resolved standard.Integer
  end Probe_Fixture
  ```

### Scenario: a parameterless subprogram is dumped like any other

A subprogram declared without a parameter list has no `Subp_Params`
node at all in the parse tree; this scenario guards the former crash
(`Precondition_Failure` on a null node, truncated dump) and pins the
expected dump. Parameter lines are optional in the grammar.

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
    procedure Reset;
    function Answer return Integer;
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    procedure Reset loc probe_fixture.ads:2:15
    function Answer loc probe_fixture.ads:3:14
      returns Integer resolved standard.Integer
  end Probe_Fixture
  ```
- And there is no error output

### Scenario: type references resolve to their declaration

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     subtype Small is Integer range 1 .. 10;
     procedure Mutate (Y : in out Small);
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    subtype Small loc probe_fixture.ads:2:14 base Integer resolved standard.Integer
      constraint 1 .. 10
    procedure Mutate loc probe_fixture.ads:3:16
      param Y loc probe_fixture.ads:3:24 mode in out type Small resolved probe_fixture.ads:2:14
  end Probe_Fixture
  ```

### Scenario: enumeration literals in declaration order

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     type Color is (Red, Green, Blue);
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    enum Color loc probe_fixture.ads:2:11 literals Red Green Blue
  end Probe_Fixture
  ```

### Scenario: static values are evaluated

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     subtype Small is Integer range 1 .. 10;
     Value : constant Integer := 2;
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    subtype Small loc probe_fixture.ads:2:14 base Integer resolved standard.Integer
      constraint 1 .. 10
    constant Value loc probe_fixture.ads:3:6 type Integer resolved standard.Integer value 2
  end Probe_Fixture
  ```

### Scenario: an index constraint is dumped

An index constraint is not a range constraint: casting it raised a
`Constraint_Error` in an earlier version (same defect family as the
parameterless crash). The backend dispatches on the constraint node
kind; an index constraint constraining exactly one index with a
static range produces the same `constraint` line — the mirror syntax
(`range` versus parentheses) is the reader's decision, driven by the
base root's kind, not the dump's ([A006]).

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
    subtype Short_Text is String (1 .. 8);
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    subtype Short_Text loc probe_fixture.ads:2:13 base String resolved standard.String
      constraint 1 .. 8
  end Probe_Fixture
  ```
- And there is no error output

### Scenario: private part is separated from the public API

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     Value : constant Integer := 2;
  private
     Internal : Integer;
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    constant Value loc probe_fixture.ads:2:6 type Integer resolved standard.Integer value 2
  private
    variable Internal loc probe_fixture.ads:4:6 type Integer resolved standard.Integer
  end Probe_Fixture
  ```

### Scenario: declarations that are not API declarations are skipped

Context lines (`with`, pragmas, `use` clauses) are not declarations of
the package API: they produce no dump line.

- Given the new file `probe_fixture.ads` containing
  ```ada
  with Ada.Strings.Unbounded;

  package Probe_Fixture is
     use Ada.Strings.Unbounded;
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:3:11
  public
  end Probe_Fixture
  ```

### Scenario: unusual declarations are reported, not dropped

A multi-line type definition stays on one line (whitespace collapsed),
and a declaration whose kind format 1 does not cover — here an
anonymous number declaration — is reported as `unhandled` ([S006]).

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     type Rec is record
        Field : Integer;
     end record;

     Answer : constant := 42;
  end Probe_Fixture;
  ```
- When I successfully run `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads`
- Then the output is
  ```text
  hac-bindgen-backend 0.1.0-dev format 1
  package Probe_Fixture loc probe_fixture.ads:1:11
  public
    type Rec loc probe_fixture.ads:2:11 definition record Field : Integer; end record
    unhandled NumberDecl loc probe_fixture.ads:6:6
  end Probe_Fixture
  ```

### Scenario: dump is deterministic

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     Value : constant Integer := 2;
  end Probe_Fixture;
  ```
- When I successfully run shell `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads > run_1.txt`
- And I successfully run shell `../tools/libadalang_backend/bin/hac_bindgen_backend probe_fixture.ads > run_2.txt`
- Then the file `run_1.txt` is equal to file `run_2.txt`
- And the file `run_1.txt` does not contain `/home/`

### Scenario: parse error produces no dump

- Given the new file `broken.ads` containing
  ```ada
  package Broken is
     procedure (this is not Ada
  end Broken;
  ```
- When I run `../tools/libadalang_backend/bin/hac_bindgen_backend broken.ads`
- Then I get an error
- And the output does not contain `format 1`

## Verification beyond bbt

- Unit tests: no separate unit-test framework; the dump grammar is
  pinned by these scenarios and by the main-crate reader
  (`Hac_Bindgen.Dump_Reader`), which rejects any deviation from the
  grammar.
- SPARK / proof: not applicable; SPARK and proof are disabled.
- Other: `alr build` in `tools/libadalang_backend` (GNAT 15.2.x) is
  part of `make check`.

## Design implications

Implements the interchange-format decision (house line-oriented text;
JSON deferred to the manifest discussion, TOML rejected) and the
backend isolation architecture. GNAT remains the legality authority
([S012]): the backend reports facts and resolution state, it does not
adjudicate legality.
