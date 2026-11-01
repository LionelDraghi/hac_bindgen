# hac_bindgen <!-- omit from toc -->

[![image](https://img.shields.io/badge/-inside-blue?logo=ada&logoColor=white&labelColor=grey&logoSize=auto)](https://ada-lang.io/)
[![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2FLionelDraghi%2Fhac_bindgen%2Fmain%2Falire.toml&query=%24.version&label=latest&style=flat-square)](https://github.com/LionelDraghi/hac_bindgen/blob/main/alire.toml)
[![bbt](https://img.shields.io/badge/bbt-54%20scenarios%20passing-brightgreen?style=flat-square)](docs/README.md)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)

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
- the HAC-side declarations (`with Import => True` stubs).

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

What hac-bindgen can and cannot bind today — scalars,
strings, records and handles cross the boundary; arrays, variant
records and function results of records are warned out — is detailed
in the [user guide](docs/user_guide.md#what-hac-bindgen-does-to-your-api).

## Getting it

The crate is not published on Alire's community index yet: clone the
repository and build it with Alire (a GNAT toolchain is required —
`alr` installs or reuses one):

```sh
git clone https://github.com/LionelDraghi/hac_bindgen
cd hac_bindgen
make build          # Alire build; the binary lands in bin/hac-bindgen
make check          # build + run the bbt executable documentation
```

## Licence

Apache-2.0, like HAC.
