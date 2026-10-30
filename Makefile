# hac_bindgen Makefile
#
# `make` (or `make check`) must be green before considering any change
# complete. `make help` lists the targets.
# See README.md, AGENTS.md and docs/dev/development_workflow.md.

ALR      ?= alr
BBT      ?= bbt
ARTIFACTS_DIR ?= artifacts
BBT_ARTIFACTS := $(ARTIFACTS_DIR)/bbt

# Executable documentation: the pages in docs/features, with runnable
# scenarios. Pages in docs/proposed are specified but not executable
# yet; they join this list when their scenarios run green.
SCENARII := ../docs/features/A001_cli.md \
            ../docs/features/A003_interchange_dump.md \
            ../docs/features/C001_usage_errors.md

BACKEND_DIR := tools/libadalang_backend

.PHONY: all help check build backend witness clean

all: check

help:
	@echo "hac_bindgen targets:"
	@echo "  make      = make all = check (build + tests)"
	@echo "  make check  build (tool + backend), then run the bbt executable documentation"
	@echo "  make build  build the tool only (validation mode)"
	@echo "  make backend  build the Libadalang analysis backend crate"
	@echo "  make clean  remove build and test artifacts"
	@echo "  make help   this list"

check: build backend
	@echo === running the bbt executable documentation
	mkdir -p $(BBT_ARTIFACTS)
	cd tests && $(BBT) -nt --yes --cleanup=full $(SCENARII)
	@echo === build and tests OK

build:
	@echo === building hac_bindgen
	$(ALR) build
	@echo OK

# The analysis backend is a separate Alire crate on the GNAT 15.x
# toolchain (see docs/dev/design_discussions.md); make check builds it
# first, the scenarios drive its executable.
backend:
	@echo === building the Libadalang backend
	cd $(BACKEND_DIR) && $(ALR) build
	@echo OK

witness:
	$(ALR) exec -- gprbuild -P tests/witness/witness.gpr
	cd tests/witness && ../../bin/witness_main.exe

clean:
	@echo === cleaning
	$(ALR) clean
	rm -rf obj bin artifacts
	find tests -name '*.in' -delete -o -name '*.out' -delete
	@echo OK
