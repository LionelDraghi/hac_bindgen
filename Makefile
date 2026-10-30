# hac_bindgen Makefile
#
# `make` (or `make check`) must be green before considering any change
# complete. `make help` lists the targets.
# See README.md, AGENTS.md and docs/dev/development_workflow.md.

ALR      ?= alr
BBT      ?= bbt
ARTIFACTS_DIR ?= artifacts
BBT_ARTIFACTS := $(ARTIFACTS_DIR)/bbt

# Executable documentation: bbt runs the scenario pages of a
# directory. `make check` runs the features pages, so a page joins the
# full validation when it lands in docs/features. The per-prefix
# targets also cover the proposed pages, so a scenario under
# specification can be run by hand. Paths are repository-root
# relative; bbt runs from tests/, hence the ../ added at invocation.
FEATURES_DIR  := docs/features
PROPOSED_DIR  := docs/proposed

ALL_SCENARII := $(filter-out $(PROPOSED_DIR)/proposal_template.md,\
                 $(wildcard $(FEATURES_DIR)/*.md) \
                 $(wildcard $(PROPOSED_DIR)/*.md))

BACKEND_DIR := tools/libadalang_backend

# One target per scenario page, by its ID prefix, case insensitive:
#   make a003, make A003, make c001, make b001, ...
SCENARIO_TARGETS := $(sort $(foreach f,$(ALL_SCENARII),\
                       $(shell basename $(f) .md | cut -d_ -f1 | tr '[:upper:]' '[:lower:]') \
                       $(shell basename $(f) .md | cut -d_ -f1)))

define RUN_SCENARIOS
@prefix=`echo $@ | tr '[:upper:]' '[:lower:]'`; \
files=; \
for f in $(ALL_SCENARII); do \
  p=`basename $$f .md | cut -d_ -f1 | tr '[:upper:]' '[:lower:]'`; \
  if [ "$$p" = "$$prefix" ]; then files="$$files ../$$f"; fi; \
done; \
if [ -z "$$files" ]; then \
  echo "no scenario matches prefix '$$prefix'" >&2; exit 1; \
fi; \
mkdir -p $(BBT_ARTIFACTS); \
cd tests && $(BBT) -nt --yes --cleanup=full $$files
endef

.PHONY: all help check build release backend witness metrics clean $(SCENARIO_TARGETS)

all: check

help:
	@echo "hac_bindgen targets:"
	@echo "  make        = make all = check (build + tests)"
	@echo "  make check  build (tool + backend), then run the bbt executable documentation"
	@echo "  make <scenario prefix, case insensitive>  run one scenario page, e.g. make a003, make b001"
	@echo "  make build  build the tool only (validation mode)"
	@echo "  make release  build the tool in release mode"
	@echo "  make backend  build the Libadalang analysis backend crate"
	@echo "  make metrics  run gnatmetric over src/, report in artifacts/metrics"
	@echo "  make clean  remove build and test artifacts"
	@echo "  make help   this list"

check: build backend
	@echo === running the bbt executable documentation
	mkdir -p $(BBT_ARTIFACTS)
	cd tests && $(BBT) -nt --yes --cleanup=full ../$(FEATURES_DIR)
	@echo === build and tests OK

$(SCENARIO_TARGETS): build backend
	$(RUN_SCENARIOS)

build:
	@echo === building hac_bindgen
	$(ALR) build
	@echo OK

#  Release-mode build: no run-time checks, optimized ([release
#  procedure], step 5).
release:
	@echo === building hac_bindgen in release mode
	$(ALR) build --release
	@echo OK

# The analysis backend is a separate Alire crate on the GNAT 15.x
# toolchain (see docs/dev/design_discussions.md); make check builds it
# first, the scenarios drive its executable.
backend:
	@echo === building the Libadalang backend
	cd $(BACKEND_DIR) && $(ALR) build
	@echo OK

# Source metrics: gnatmetric comes from libadalang_tools, built with
# the backend crate (GNAT 15); the per-source .metrix files and the
# text report land under artifacts/, not in the sources.
GNATMETRIC := $(shell ls $$HOME/.local/share/alire/builds/libadalang_tools_*/*/bin/gnatmetric 2>/dev/null | head -1)

witness:
	$(ALR) exec -- gprbuild -P tests/witness/witness.gpr
	cd tests/witness && ../../bin/witness_main.exe

metrics:
	@echo === source metrics with gnatmetric
	if [ -z "$(GNATMETRIC)" ]; then \
	  echo "gnatmetric not found; build tools/libadalang_backend (it provides libadalang_tools)" >&2; exit 1; fi
	mkdir -p $(ARTIFACTS_DIR)/metrics
	$(GNATMETRIC) --complexity-all src/*.ads src/*.adb --output-dir $(ARTIFACTS_DIR)/metrics
	@echo OK

clean:
	@echo === cleaning
	$(ALR) clean
	rm -rf obj bin artifacts
	find tests -name '*.in' -delete -o -name '*.out' -delete
	@echo OK
