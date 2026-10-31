# docs — the user-facing documentation <!-- omit from toc -->

This directory holds what the users need to know about hac-bindgen:
the user guide, the error codes, the roadmap, and the specifications.
It is not maintainer-facing documentation: that lives in
[`docs/dev/`](dev/) — the two indexes point to each other, so if you
got lost, follow that way.

## In this directory

| File | Role |
|---|---|
| [user_guide.md](user_guide.md) | how to use hac-bindgen: the commands, the generated files, the embedding, and what the tool does to the API |
| [manifesto.md](manifesto.md) | the motivation and the principles |
| [roadmap.md](roadmap.md) | the prioritised development plan |
| [features/](features/) | the feature specifications, executable through their bbt scenarios; the [HACBxxxx error-code catalogue](features/B001_non_bindable_constructs.md#the-catalogue) lives there |
| [proposed/](proposed/) | features under specification, not executable yet |
| [specifications.md](specifications.md) | the specification structure and the index of features |
| [changelog.md](changelog.md) | notable changes from a user perspective, newest first |

The shared rules — responsibilities, naming conventions, proposal
lifecycle, changelog conventions — live in the reference repository,
[`documentation_structure.md`](https://github.com/LionelDraghi/ada-project-template/blob/main/documentation_structure.md),
and apply here in full.
