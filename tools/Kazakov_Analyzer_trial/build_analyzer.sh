#!/bin/sh
# Build the Kazakov Ada syntax analyzer test driver (tools/Kazakov_Analyzer_trial/kazakov)
set -e
KAZ=$(CDPATH= cd -- "$(dirname -- "$0")/kazakov" && pwd)

# Prefer the Alire toolchains when present (Linux and Windows layouts),
# fall back to whatever gnat/gprbuild are already in PATH.
for TC in "$HOME/.local/share/alire/toolchains" \
          "$HOME/AppData/Local/alire/cache/toolchains"; do
    if [ -d "$TC" ]; then
        GNAT_DIR=$(ls -d "$TC"/gnat_native_* 2>/dev/null | sort -V | tail -1)
        GPB_DIR=$(ls -d "$TC"/gprbuild_* 2>/dev/null | sort -V | tail -1)
        if [ -n "$GNAT_DIR" ] && [ -n "$GPB_DIR" ]; then
            export PATH="$GNAT_DIR/bin:$GPB_DIR/bin:$PATH"
            break
        fi
    fi
done

cd "$KAZ"

# Generate the wrapper project: the directory holds exactly the sources
# required by the analyzer, so no explicit source list is needed.
{
  echo 'project Analyzer_Test is'
  echo '   for Languages use ("Ada");'
  echo '   for Source_Dirs use (".", "test_suite");'
  echo '   for Main use ("test_suite.adb");'
  echo '   for Object_Dir use "obj_analyzer";'
  echo '   for Exec_Dir use "bin";'
  echo 'end Analyzer_Test;'
} > analyzer_test.gpr

gprbuild -P analyzer_test.gpr -j4
