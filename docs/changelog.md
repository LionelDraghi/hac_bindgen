# Changelog

All notable changes to this project are documented in this file,
following [Keep a Changelog](https://keepachangelog.com/) conventions.
Update the Unreleased section during Finalize; do not bump the version
until Release.

## [Unreleased]

### Added

- `tools/libadalang_backend`: Libadalang analysis backend in its own
  Alire crate (GNAT 15.x, Libadalang 26.0.0), isolated from the main
  crate which stays on GNAT 16.
- Interchange dump format 1 emitted by `hac_bindgen_backend` and
  specified as feature A003, with bbt scenarios in
  `docs/features/A003_interchange_dump.md`.

### Changed

- `make check` now builds the backend crate before running the bbt
  scenarios.

