#!/bin/sh
# Build the Kazakov Ada syntax analyzer test driver (tools/essai_2/kazakov)
set -e
KAZ=/c/Users/ldraghi/Private/GitHub/hac_bindgen/tools/essai_2/kazakov
TC=$HOME/AppData/Local/alire/cache/toolchains
export PATH="$TC/gnat_native_15.3.1_ebcc0106/bin:$TC/gprbuild_26.0.1_68a6817f/bin:$PATH"

cd "$KAZ"

# Generate the wrapper project: reuse the source list from the shipped
# components-ada-syntax_analyzer.gpr but with local withs and a main.
{
  echo 'with "components.gpr";'
  echo 'with "components-ada.gpr";'
  echo 'project Analyzer_Test is'
  echo '   for Languages use ("Ada");'
  echo '   for Source_Dirs use (".", "test_suite");'
  echo '   for Source_Files use ('
  # extract the quoted file names of the analyzer project
  grep -o '"[^"]*\.ad[sb]"' components-ada-syntax_analyzer.gpr | /usr/bin/sed 's/\r//'
  echo '   "test_suite.adb");'
  echo '   for Main use ("test_suite.adb");'
  echo '   for Object_Dir use "obj_analyzer";'
  echo '   for Exec_Dir use "bin";'
  echo 'end Analyzer_Test;'
} > analyzer_test.gpr

gprbuild -P analyzer_test.gpr -j4
