# C002 — Runtime boundary errors

The API shape is legal and bound, but the HAC program supplies an
invalid runtime value, or the native application raises. These are the
class-2 and class-3 failures of [S007] — distinct from the generation
warnings of [B001] and the usage errors of [C001]:

> non-bindable API shapes are warned at generation time;
> invalid runtime values fail at execution time.

Boundary errors are reported by the generated callback through HAC's
actual error mechanism, derived from the real implementation in M2 —
never converted into a default scalar result, never swallowed ([S003]).

Status: specified, not yet executable — the scenarios below move to bbt
form as the generation chain lands (M4).

## Planned scenarios

| ID | Scenario | Exercised behavior |
|---|---|---|
| C002-01 | an out-of-range integer fails at the boundary | the script sends an integer outside the native subtype range ([A002-10]): the generated conversion check reports a boundary error, the script sees HAC's error report |
| C002-02 | an invalid enumeration position fails at the boundary | the script sends an out-of-range enum value: defined error ([S003]) |
| C002-03 | a wrong argument count is detected | the callback checks the arity it receives against the registered signature |
| C002-04 | a native application exception is reported, not swallowed | the façade raises (e.g. unknown handle): the generated adapter translates it through HAC's error mechanism ([S007] class 3) |
| C002-05 | an unrepresentable result is reported | the native result cannot be converted (out-of-range return value): boundary error, no default value ([S003]) |
