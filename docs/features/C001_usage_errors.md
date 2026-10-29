# C001 — Usage and input errors

Usage errors and tool failures: bad command lines, unreadable inputs,
files that are not Ada specifications. These are distinct from the
non-bindable-construct warnings of [B001](B001_non_bindable_constructs.md):
here the tool cannot do its job at all ([S007], [S010]).

## Scenario: a missing input file is an error

- When I run `../bin/hac-bindgen check no_such_file.ads`
- Then the error output contains `no_such_file.ads`
- And the exit code is `1`

## Scenario: an input that is not an Ada specification is an error

A text file that the analyser cannot read as an Ada package
specification is a tool error, reported with the file name and the
analyser message — not a traversal warning.

- Given the file `not_ada.ads` containing:
  ```text
  this is not Ada
  ```
- When I run `../bin/hac-bindgen check not_ada.ads`
- Then the error output contains `not_ada.ads`
- And the exit code is `1`
