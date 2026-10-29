# hac_bindgen Makefile
#
# Run `make help` for the target list; `make check` before considering
# any change complete.
# See README.md, AGENTS.md and docs/dev/development_workflow.md.

ALR ?= alr
# The recipes use pipefail, which requires a POSIX-shell feature set that
# /bin/sh does not guarantee (dash lacks it). The shell is resolved from
# the PATH, not from an absolute path, so that a native make on Windows
# can run the recipes with Git Bash.
SHELL := bash

BBT ?= bbt
ARTIFACTS_DIR ?= artifacts
BBT_ARTIFACTS := $(ARTIFACTS_DIR)/bbt

# Executable documentation: the feature pages with runnable scenarios.
# Pages in docs/proposed are specified but not executable yet; they join
# this list when their scenarios run green.
SCENARII := ../docs/features/A001_cli.md \
            ../docs/features/C001_usage_errors.md

BUILD_TARGET := hac_bindgen

.PHONY: help build test check clean

help:
	@grep -E '^# |^[a-z_-]+:' $(firstword $(MAKEFILE_LIST)) \
	  | grep -v -E '(^#   |\^\^|##)' \
	  | sed 's/\(:.*:\)/\n\1/' \
	  | awk -F'[:,]' '{ if ($$1 == "#") { printf "\n%s\n", $$0 } else { printf "  %-14s %s\n", $$1, $$3 } }'

build:
	@echo
	@echo === building hac_bindgen
	$(ALR) build
	@echo OK

test:
	@echo
	@echo === running the bbt executable documentation
	mkdir -p $(BBT_ARTIFACTS)
	cd tests && $(BBT) -nt --cleanup=full --yes $(SCENARII)
	@echo OK

check: build test
	@echo
	@echo === build and tests OK

clean:
	@echo
	@echo === cleaning
	$(ALR) clean
	rm -rf obj bin $(ARTIFACTS_DIR)
	find tests -name '*.in' -delete -o -name '*.out' -delete
	@echo OK
