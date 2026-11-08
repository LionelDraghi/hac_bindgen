#  hac_bindgen — docs/examples/Makefile
#
#  The Geometry example, self-contained: generate the binding,
#  compile the embedding demo, run the bbt scenarios of README.md —
#  and clean everything those runs leave behind.
#
#  The hac-bindgen tool and the Libadalang backend are expected to
#  exist: built from the repository root with `make build` and
#  `make backend`.

HAC_BINDGEN         ?= ../../bin/hac-bindgen
HAC_BINDGEN_BACKEND ?= ../../tools/libadalang_backend/bin/hac_bindgen_backend
BBT ?= bbt
ALR ?= alr

.PHONY: help build check clean

help:
	@echo "docs/examples targets:"
	@echo "  make build   generate the binding, then compile the demo"
	@echo "  make check   run the bbt scenarios of README.md"
	@echo "               (they regenerate and rebuild everything)"
	@echo "  make clean   remove the residues: obj/, the binary, the"
	@echo "               bbt dumps, and the generated binding"

build:
	HAC_BINDGEN_BACKEND=$(HAC_BINDGEN_BACKEND) $(HAC_BINDGEN) generate src/geometry.ads --output-dir generated_src --hac-package HAC_Geometry
	$(ALR) exec -- gprbuild -q -P demo.gpr

check:
	$(BBT) --yes README.md

clean:
	rm -rf obj
	rm -f demo_main *.out
	rm -f generated_src/*.ad?
