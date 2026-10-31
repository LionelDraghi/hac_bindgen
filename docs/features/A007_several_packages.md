# A007 — Several bound packages in one HAC environment <!-- omit from toc -->

Real applications bind more than one package: a geometry API and a
logging API, two vendor specifications, a main API and its helpers.
`generate` already accepts several sources in one invocation
(`SOURCE...`, [A001]) and processes each independently; this page
owns what makes the outputs compose rather than collide.

## Intended outcome

A witness application registers two generated adapters with two
`Register_All` calls into one HAC environment, and one script `with`es
both generated packages and calls operations in each. Two packages
declaring an operation with the same simple name both bind and both
work: HAC resolves a package operation by its qualified name
(`FIRST_API.SAY` versus `SECOND_API.SAY`), so no registration collides.
Inputs that would silently produce a broken file set — two sources
declaring the same package name, or `--hac-package` applied to several
sources — are rejected with a diagnostic instead.

## Specification

Generation stays per source: `generate` analyses and classifies each
specification independently; the feature is that the outputs compose,
not a cross-package analysis. The composition rests on three verified
facts:

- **Registration names are package-qualified** ([A002]): `Register
  (BD, Callback'Access, "FIRST_API.SAY")`. Two packages exposing the
  same simple name register under different qualified names; HAC
  replaces an entry only when the *full* name matches (M2 evidence,
  `docs/dev/hac_interfacing_notes.md`).
- **The HAC librarian resolves a unit by file naming**: the generated
  HAC-side packages of two distinct APIs live in distinct
  `<unit>.ads`/`<unit>.adb` files; one script `with`es both.
- **The registry helper is deterministic** ([A002-08]): two
  generation runs needing the helper emit byte-identical
  `hac_bindgen_handles.ads`/`.adb` into the output directory; the
  second run overwrites the first with the same bytes, both native
  packages `with` the one unit, and each instantiates its registry
  locally in its own body — the set compiles as one GNAT project.

Two inputs are diagnosed instead of silently producing a broken file
set: two sources declaring the same package name, and `--hac-package`
with several sources. Both rejections are input errors ([C001]
family): exit status 1, diagnostic on the error output, nothing
generated.

## Executable scenarios

| Scenario | Behavior |
|---|---|
| A007-01 | two bound packages register into one HAC environment |
| A007-02 | two packages expose the same operation name |
| A007-03 | two sources declaring the same package name are rejected |
| A007-04 | `--hac-package` with several sources is rejected |

### Scenario: two bound packages register into one HAC environment

Two invocations generate both façades into `run`; the shim calls both
`Register_All`; the script `with`es both generated packages.

- Given the new directory `run`
- Given the new file `run/first_api.ads` containing
  ```ada
  package First_Api is
     procedure Ping (X : in Integer);
  end First_Api;
  ```
- Given the new file `run/first_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body First_Api is
     procedure Ping (X : in Integer) is
     begin
        Ada.Text_IO.Put_Line ("native: Ping" & Integer'Image (X));
     end Ping;
  end First_Api;
  ```
- Given the new file `run/second_api.ads` containing
  ```ada
  package Second_Api is
     procedure Echo (X : in Integer);
  end Second_Api;
  ```
- Given the new file `run/second_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Second_Api is
     procedure Echo (X : in Integer) is
     begin
        Ada.Text_IO.Put_Line ("native: Echo" & Integer'Image (X));
     end Echo;
  end Second_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/first_api.ads --output-dir run --hac-package HAC_First_Api`
- When I successfully run `../bin/hac-bindgen generate run/second_api.ads --output-dir run --hac-package HAC_Second_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with HAC_Sys.Builder;
  package Witness_Binding is
     procedure Register_All (BD : HAC_Sys.Builder.Build_Data);
  end Witness_Binding;
  ```
- Given the new file `run/witness_binding.adb` containing
  ```ada
  with First_Api_Native;
  with Second_Api_Native;
  package body Witness_Binding is
     procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
     begin
        First_Api_Native.Register_All (BD);
        Second_Api_Native.Register_All (BD);
     end Register_All;
  end Witness_Binding;
  ```
- Given the new file `run/two_packages_script.adb` containing
  ```ada
  with HAC_First_Api;
  with HAC_Second_Api;
  procedure Two_Packages_Script is
  begin
     HAC_First_Api.Ping (1);
     HAC_Second_Api.Echo (2);
  end Two_Packages_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/two_packages_script.adb`
- Then I get
  ```text
  native: Ping 1
  native: Echo 2
  E2E: script completed.
  ```

### Scenario: two packages expose the same operation name

Both packages declare `Say`; both bind — no warning — and both work:
the qualified registration names differ.

- Given the new directory `run`
- Given the new file `run/first_api.ads` containing
  ```ada
  package First_Api is
     procedure Say (N : in Integer);
  end First_Api;
  ```
- Given the new file `run/first_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body First_Api is
     procedure Say (N : in Integer) is
     begin
        Ada.Text_IO.Put_Line ("native: first Say" & Integer'Image (N));
     end Say;
  end First_Api;
  ```
- Given the new file `run/second_api.ads` containing
  ```ada
  package Second_Api is
     procedure Say (N : in Integer);
  end Second_Api;
  ```
- Given the new file `run/second_api.adb` containing
  ```ada
  with Ada.Text_IO;
  package body Second_Api is
     procedure Say (N : in Integer) is
     begin
        Ada.Text_IO.Put_Line ("native: second Say" & Integer'Image (N));
     end Say;
  end Second_Api;
  ```
- When I successfully run `../bin/hac-bindgen generate run/first_api.ads --output-dir run --hac-package HAC_First_Api`
- When I successfully run `../bin/hac-bindgen generate run/second_api.ads --output-dir run --hac-package HAC_Second_Api`
- Given the new file `run/witness_binding.ads` containing
  ```ada
  with HAC_Sys.Builder;
  package Witness_Binding is
     procedure Register_All (BD : HAC_Sys.Builder.Build_Data);
  end Witness_Binding;
  ```
- Given the new file `run/witness_binding.adb` containing
  ```ada
  with First_Api_Native;
  with Second_Api_Native;
  package body Witness_Binding is
     procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
     begin
        First_Api_Native.Register_All (BD);
        Second_Api_Native.Register_All (BD);
     end Register_All;
  end Witness_Binding;
  ```
- Given the new file `run/same_name_script.adb` containing
  ```ada
  with HAC_First_Api;
  with HAC_Second_Api;
  procedure Same_Name_Script is
  begin
     HAC_First_Api.Say (1);
     HAC_Second_Api.Say (2);
  end Same_Name_Script;
  ```
- When I successfully run shell `alr exec -- gprbuild -q -P e2e/witness.gpr`
- When I successfully run `./run/witness_main run/same_name_script.adb`
- Then I get
  ```text
  native: first Say 1
  native: second Say 2
  E2E: script completed.
  ```

### Scenario: two sources declaring the same package name are rejected

- Given the new directory `run`
- Given the new file `run/a.ads` containing
  ```ada
  package Same_Name is
     procedure Ping (X : in Integer);
  end Same_Name;
  ```
- Given the new file `run/b.ads` containing
  ```ada
  package Same_Name is
     procedure Pong (X : in Integer);
  end Same_Name;
  ```
- When I run `../bin/hac-bindgen generate run/a.ads run/b.ads --output-dir run`
- Then the exit code is `1`
- And the error output contains `Same_Name`

### Scenario: --hac-package with several sources is rejected

- Given the new directory `run`
- Given the new file `run/first_api.ads` containing
  ```ada
  package First_Api is
     procedure Ping (X : in Integer);
  end First_Api;
  ```
- Given the new file `run/second_api.ads` containing
  ```ada
  package Second_Api is
     procedure Echo (X : in Integer);
  end Second_Api;
  ```
- When I run `../bin/hac-bindgen generate run/first_api.ads run/second_api.ads --output-dir run --hac-package HAC_Api`
- Then the exit code is `1`
- And the error output contains `--hac-package`
