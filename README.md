# hac_bindgen <!-- omit from toc -->

Embed the [HAC](https://github.com/zertovitch/hac) Ada interpreter in
your Ada application: users write scripts that run inside the program
and call its functions. Exposing those functions to a script takes
boilerplate — native callbacks, value conversions, registration, and
mirrored declarations. hac-bindgen generates all of it from your
package specification.

**An Ada-to-HAC binding generator: expose a native Ada API to embedded
HAC scripts without writing the interfacing glue by hand.**

`hac-bindgen` traverses ordinary Ada package specifications and generates
everything an embedded [HAC](https://github.com/zertovitch/hac) program
needs to call native code:

- the native adapter (argument retrieval, conversion, call, result
  conversion, callback registration), built on `HAC_Sys.Interfacing`;
- the HAC-side declarations (`with Import => True` stubs);
- the binding manifest.

Everything the API exposes and that hac-bindgen can bind is bound.
Everything it cannot bind is reported as a warning — never silently
dropped, and never a reason to reject the whole package.

## Documentation

### For the curious reader

Read the [manifesto](docs/manifesto.md) — the motivation and the
principles.

### For users

Read the [user documentation index](docs/README.md), which contains
in particular:

- the [user guide](docs/user_guide.md);
- the [error codes](docs/features/B001_non_bindable_constructs.md#the-catalogue) (the HACBxxxx catalogue);
- the [changelog](docs/changelog.md).

If you hit a problem, you may also be interested in the known
difficulties and limitations listed in the
[open-work index](docs/dev/concerns.md).

### For developers

Read the [maintainer documentation index](docs/dev/README.md), which
contains in particular:

- the [development workflow](docs/dev/development_workflow.md);
- the [design discussions](docs/dev/design_discussions.md).

## Status

Development.

## Build and test

```sh
make build   # Alire build
make check   # build + bbt executable documentation
make a003    # shortcut to run A003_interchange_dump.md scenario
```

## Licence

Apache-2.0, like HAC.
