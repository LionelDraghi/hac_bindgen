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

