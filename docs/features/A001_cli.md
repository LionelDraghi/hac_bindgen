# A001 — Command-line interface

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

Planned options, added as the features that need them land (the
original manifesto's §10.2 explicit-generation form):

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

## Scenario: version reporting

[S002] — the version identifies the generator, and the same version
appears in every generated artefact of a run.

- When I successfully run `../bin/hac-bindgen --version`
- Then the output matches `hac-bindgen [0-9]+\.[0-9]+\.[0-9]+.*`

## Scenario: help

- When I successfully run `../bin/hac-bindgen --help`
- Then the output contains `usage`
- And the output contains `generate`
- And the output contains `check`

## Scenario: an unknown option is rejected

- When I run `../bin/hac-bindgen --frobnicate`
- Then the error output contains `usage`
- And the exit code is `1`
