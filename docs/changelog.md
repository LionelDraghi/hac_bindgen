# Changelog <!-- omit from toc -->

All notable changes **from a user perspective** to this project are
documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and the version numbering on [Semantic Versioning](https://semver.org/).

During development, entries accumulate under the current `-dev` version
section, dated `????-??-??` until release; the newest entry comes first.

- **[0.1.0-dev] - 2026-??-??**
  - [Added] Ada package specifications are now analyzed: `hac-bindgen check` runs the isolated Libadalang backend on each source and builds the validated binding model from its format-1 interchange dump; the format is frozen (cf. docs/features/A003_interchange_dump.md, docs/features/A001_cli.md)
