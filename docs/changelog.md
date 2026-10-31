# Changelog <!-- omit from toc -->

All notable changes **from a user perspective** to this project are
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and the version numbering on [Semantic Versioning](https://semver.org/).

During development, entries accumulate under the current `-dev` version
section, dated `????-??-??` until release; the newest entry comes first.

- **[0.1.0-dev] - 2026-??-??**
  - [Added] enumerations with character literals are warned out with the stable identifier HACB0017 — HAC cannot parse such declarations, so no mirror is emitted and every operation using the type counts as not bound; enumeration representation clauses and enumeration-returning functions are pinned end to end (cf. docs/features/A005_enumerations.md)
  - [Fixed] the analysis backend no longer crashes on a subprogram declared without a parameter list (`procedure Reset;`, `function Answer return Integer;`): it now produces the normal dump (cf. docs/features/A003_interchange_dump.md)
  - [Added] `hac-bindgen generate` produces the scripting facade of the scalar profile: the native adapter (callbacks, conversions, registration) and the HAC-side declarations, generated from the bound part of the API only, with `--output-dir` and `--hac-package` to fit the project layout (cf. docs/features/A002_facade_generation.md)
  - [Added] `hac-bindgen check` classifies the public API: every declaration is reported as bound or warned out, with a stable HACBxxxx identifier, a source location, and a reason, closed by a per-package bound / not bound summary (cf. docs/features/B001_non_bindable_constructs.md)
  - [Added] Ada package specifications are now analyzed: `hac-bindgen check` runs the isolated Libadalang backend on each source and builds the validated binding model from its format-1 interchange dump; the format is frozen (cf. docs/features/A003_interchange_dump.md, docs/features/A001_cli.md)
