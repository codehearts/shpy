#!/usr/bin/env sh

# Determine the location of this script, and subsequently the renamer script
renamer_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

# Add `renamer` to the path
PATH="$PATH:$renamer_dir"

# If kcov is collecting test coverage, run `renamer` with bash
# `renamer` usually runs with sh, but kcov can only collect metrics with bash
if [ -n "${KCOV_BASH_COMMAND:+is_set}" ]; then
  renamer() { bash renamer "$@"; }
fi

# Verify the renaming pattern begins at 1 and renames a single file correctly
test_itStartsPatternAt1WhenRenamingSingleFile() {
  # Create a spy for mv to verify how the renamer script calls it
  createSpy mv

  renamer 'photo-*.jpg' img123.jpg

  # Verify the file was renamed to the pattern, which started with 1
  assertCalledWith_ 'file not renamed correctly' mv img123.jpg photo-1.jpg
}

# Verify the renaming pattern increments for subsequent files
test_itIncrementsPatternTo2WhenRenamingTwoFiles() {
  # Create a spy for mv to verify how the renamer script calls it
  createSpy mv

  renamer 'photo-*.jpg' img123.jpg img456.jpg

  # Skip examining the first call, which was verified by the previous test
  examineNextSpyCall mv

  # Verify the second file was renamed to the pattern with index 2
  assertCalledWith_ 'file not renamed correctly' mv img456.jpg photo-2.jpg
}

# Verify that a failed rename is skipped, and the next file is renamed
test_itContinuesWhenFileFailsToRename() {
  # Create a spy for mv which fails on its second call only
  createSpy -r 0 -r 1 -r 0 mv

  renamer 'photo-*.jpg' img123.jpg img456.jpg img789.jpg

  # Verify all three files were renamed, despite the second rename failing
  assertCalledWith_ 'first file not renamed correctly' mv img123.jpg photo-1.jpg
  assertCalledWith_ 'second file not renamed correctly' mv img456.jpg photo-2.jpg
  assertCalledWith_ 'did not continue after failure' mv img789.jpg photo-3.jpg
}

# Verify that a single failed rename causes the script to return 1
test_itReturns1WhenSingleFileFailsToRename() {
  # Create a spy for mv which fails on its second call only
  createSpy -r 0 -r 1 -r 0 mv

  renamer 'photo-*.jpg' img123.jpg img456.jpg img789.jpg

  # Verify the exit status of the previous command is 1
  assertEquals 'did not return 1 after single failure' 1 $?
}

# Verify that multiple failed renames cause the script to return 1
test_itReturns1WhenMultipleFilesFailToRename() {
  # Create a spy for mv which fails on every call
  createSpy -r 1 mv

  renamer 'photo-*.jpg' img123.jpg img456.jpg img789.jpg

  # Verify the exit status of the previous command is 1
  assertEquals 'did not return 1 after multiple failures' 1 $?
}

# Verify that output to stderr from mv is displayed
test_itDisplaysErrorOutputFromMv() {
  # Create a spy for mv which outputs to stderr
  createSpy -e 'test error output' mv

  # Verify that stderr contains the output to stderr from mv
  assertEquals 'did not display stderr from mv' \
    'test error output' "$(renamer 'photo-*.jpg' img123.jpg 2>&1 >/dev/null)"
}

# Verify that usage info is displayed when too few args are passed
# This test doesn't need to utilize spies, but is good for full test coverage!
test_itDisplaysUsageWithTooFewArgs() {
  # The output should contain the usage line when called with 0 args
  renamer | grep -q 'Usage: .\+ RENAMING_PATTERN FILE...'
  assertTrue 'usage was not displayed with 0 args' $?

  # The output should contain the usage line when call with 1 arg
  renamer abc | grep -q 'Usage: .\+ RENAMING_PATTERN FILE...'
  assertTrue 'usage was not displayed with 1 arg' $?
}

# Verify that the script returns 1 when too few args are passed
# This test doesn't need to utilize spies, but is good for full test coverage!
test_itReturns1WithTooFewArgs() {
  # The script should exit 1 with 0 args
  renamer >/dev/null
  assertEquals 'did not exit with status code 1 with 0 args' 1 $?

  # The script should exit 1 with 1 arg
  renamer abc >/dev/null
  assertEquals 'did not exit with status code 1 with 1 arg' 1 $?
}

# Remove all spies after each test
tearDown() {
  cleanupSpies
}

# Include shpy with its shunit2 integration
. /shpy/shpy
. /shpy/shpy-shunit2

# Source the shunit2 unit testing framework to run the tests
. /usr/local/bin/shunit2
