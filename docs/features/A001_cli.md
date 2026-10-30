# A001 — Command-line interface <!-- omit from toc -->

`hac-bindgen` is a command-line tool; the CLI is its sole entry point
([S010]). This page owns the command surface: subcommands, options, exit
status, version reporting. The detailed per-command behavior of
`generate` is specified in
[A002](A002_facade_generation.md), the diagnostics in
[B001](B001_non_bindable_constructs.md) and [C001](C001_usage_errors.md).

Command surface:

```text
hac-bindgen generate SOURCE... [--output-dir DIR]
hac-bindgen check    SOURCE... [--output-dir DIR]
hac-bindgen --version
hac-bindgen --help
```

Planned options, added as the features that need them land:

```text
--native-package NAME   name of the generated native child package
--hac-package NAME      name of the generated HAC declaration package
--manifest FILE         path of the binding manifest (gadget)
--diagnostics text|gcc  warning format (gadget)
```

`generate` analyses the supplied package specification(s), binds what it
can and writes the generated files ([S006]). `check` runs the same
traversal and reports the bindable / non-bindable classification
without writing any generated file. Both report the traversal summary:
what was bound, what was warned, and why — with the counts and, for the
not-bound part, the warnings of [B001].

## Contents <!-- omit from toc -->

- [Scenario: version reporting](#scenario-version-reporting)
- [Scenario: help](#scenario-help)
- [Scenario: no argument means help](#scenario-no-argument-means-help)
- [Scenario: an unknown option is rejected](#scenario-an-unknown-option-is-rejected)
- [Analysis backend](#analysis-backend)
  - [Scenario: check analyses a valid specification](#scenario-check-analyses-a-valid-specification)

## Scenario: version reporting

[S002] — the version identifies the generator, and the same version
appears in every generated artefact of a run.

- When I successfully run `../bin/hac-bindgen --version`
- Then the output matches `hac-bindgen [0-9]+\.[0-9]+\.[0-9]+.*`

## Scenario: help

- When I successfully run `../bin/hac-bindgen --help`
- Then the output is
  ```text
  usage: hac-bindgen generate SOURCE... [--output-dir DIR]
         hac-bindgen check SOURCE... [--output-dir DIR]
         hac-bindgen --version
         hac-bindgen --help
  ```

## Scenario: no argument means help

Invoking `hac-bindgen` without any argument is equivalent to
`--help`: same output, same exit status.

- When I successfully run `../bin/hac-bindgen`
- Then the output is
  ```text
  usage: hac-bindgen generate SOURCE... [--output-dir DIR]
         hac-bindgen check SOURCE... [--output-dir DIR]
         hac-bindgen --version
         hac-bindgen --help
  ```

## Scenario: an unknown option is rejected

- When I run `../bin/hac-bindgen --frobnicate`
- Then the error output is
  ```text
  error: invalid command '--frobnicate'
  usage: hac-bindgen generate SOURCE... [--output-dir DIR]
         hac-bindgen check SOURCE... [--output-dir DIR]
         hac-bindgen --version
         hac-bindgen --help
  ```
- And the exit code is `1`

## Analysis backend

`check` and `generate` run the analysis backend executable on each
source and build the binding model from its dump — the main tool never
links the analysis library (backend isolation decision in
[design discussions](../dev/design_discussions.md)). The backend is
located through the `HAC_BINDGEN_BACKEND` environment variable when it
is set, then relative to the current directory
(`tools/libadalang_backend/bin/hac_bindgen_backend` from the repository
root, `../tools/...` from `tests/`).

### Scenario: check analyses a valid specification

The source is analyzed through the backend, and the model is built and
validated; on success the traversal warnings and summary are printed
on the standard output (specified in
[B001](B001_non_bindable_constructs.md)).

- Given the new file `probe_fixture.ads` containing
  ```ada
  package Probe_Fixture is
     procedure Ping (X : in Integer);
  end Probe_Fixture;
  ```
- When I run `../bin/hac-bindgen check probe_fixture.ads`
- Then there is no error
