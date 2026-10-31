# Changelog <!-- omit from toc -->

All notable changes **from a user perspective** to this project are
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and the version numbering on [Semantic Versioning](https://semver.org/).

- **[0.1.1-dev] - ????-??-??**

- **[0.1.0] - 2026-10-31**
  - [Added] `hac-bindgen generate` produces the scripting facade of a package specification: the native adapter (callbacks, conversions, registration) and the HAC-side declarations, from the bound part of the API, with `--output-dir` and `--hac-package` to fit the project layout
  - [Added] `hac-bindgen check` classifies the public API: every declaration reported as bound or warned out, with a stable HACBxxxx identifier, a source location, a reason, and a per-package bound / not bound summary
  - [Added] the analysis runs in an isolated Libadalang backend, communicating through a frozen format-1 interchange dump
  - [Added] boundary profiles: scalar `out` / `in out` copy-back, private and tagged private types crossed as integer handles with an explicit `Drop`, enumerations with character literals warned out, and strings end to end (`VString` exchange, bounded subtypes warned out)
  - [Added] several bound packages compose in one HAC environment; ambiguous multi-source invocations (duplicate package name, `--hac-package` with several sources) are rejected
  - [Fixed] the analysis backend no longer crashes on a parameterless subprogram declaration or on an index-constrained string subtype: both produce the normal dump
