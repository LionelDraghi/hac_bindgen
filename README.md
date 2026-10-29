# hac_bindgen

**An Ada-to-HAC binding generator: expose a native Ada API to embedded
HAC scripts without writing the interfacing glue by hand.**

`hac-bindgen` traverses ordinary Ada package specifications — the rich
application API or a hand-written scripting façade — and generates
everything an embedded [HAC](https://github.com/zertovitch/hac) program
needs to call native code:

- the native adapter (argument retrieval, conversion, call, result
  conversion, callback registration), built on `HAC_Sys.Interfacing`;
- the HAC-side declarations (`with Import => True` stubs);
- the binding manifest.

Everything the API exposes and that hac-bindgen can bind is bound.
Everything it cannot bind is reported as a warning — never silently
dropped, and never a reason to reject the whole package.

## Status

Experimental. See [docs/manifesto.md](docs/manifesto.md) for the
motivation and the principles, and
[docs/specifications.md](docs/specifications.md) for the specification
structure and the index of features.

## Build and test

```sh
make build   # Alire build
make check   # build + bbt executable documentation
```

## Licence

Apache-2.0, like HAC.
