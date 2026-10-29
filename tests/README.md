# tests

The bbt run directory: scenarios execute here, so their relative
paths (`../bin/hac-bindgen`, `../docs/features/...`) resolve inside
the repository. Runtime files produced by scenarios are not
version-controlled; witness sources are.

Run with `make check` from the repository root.

The manually written HAC callback witness is built and run with
`make witness`. It compiles scripts in the embedded HAC VM and checks
package imports, callback results and conversions, copy-back, and
boundary error propagation.
