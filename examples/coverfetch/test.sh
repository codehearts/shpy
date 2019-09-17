#!/usr/bin/env sh

# Determine the location of this script, and subsequently the coverfetch script
coverfetch_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

# Add the coverfetch to the path
PATH="$PATH:$coverfetch_dir"

# If kcov is collecting test coverage, run `coverfetch` with bash
# `coverfetch` usually runs with sh, but kcov can only collect metrics with bash
if [ -n "${KCOV_BASH_COMMAND:+is_set}" ]; then
  coverfetch() { bash coverfetch "$@"; }
fi

# Verifies the following:
# - The MusicBrainz endpoint is queried with the given artist and album
test_itQueriesMusicBrainzApiWithArtistAndAlbum() {
  # Create a spy for curl
  # Call 1: Returns 0 and outputs a sample JSON response to stdout
  # Call 2: Returns 0 and outputs 200 to stdout
  createSpy -r 0 -o '{"releases":[{"id":"test-id-123","title":"Flamingo"}]}' \
    -r 0 -o '200' \
    curl

  coverfetch 'kero kero bonito' 'flamingo'

  # Check if the curl arguments contained the endpoint URL
  getArgsForCall curl 1 | grep -q 'http://musicbrainz.org/ws/2/release/'
  assertTrue 'MusicBrainz API endpoint was not queried' $?

  # Check if the curl arguments contained the artist/album query
  getArgsForCall curl 1 | grep -q "query=artist:'kero kero bonito' AND release:'flamingo'"
  assertTrue 'MusicBrainz API endpoint was not queried' $?
}

# Verifies the following:
# - MBID from the endpoint is parsed correctly and used to fetch artwork
# - MBID can contain lowercase letters, digits, and hyphens
test_itUsesMusicBrainzIdToDownloadCoverArt() {
  # Create a spy for curl
  # Call 1: Returns 0 and outputs a sample JSON response to stdout
  # Call 2: Returns 0 and outputs 200 to stdout
  createSpy -r 0 -o '{"releases":[{"id":"test-id-123","title":"Flamingo"}]}' \
    -r 0 -o '200' \
    curl

  coverfetch 'kero kero bonito' 'flamingo'

  # Skip the first call to curl and examine the second call
  examineNextSpyCall curl

  # Verify the second call to curl used the MBID in its request
  assertCalledWith_ 'MBID was not used to fetch artwork' \
    curl --silent --location --get \
    --output 'cover.png' --write-out '%{http_code}' \
    'http://coverartarchive.org/release/test-id-123/front-500.png'
}

# Verifies the following:
# - An error is displayed when the `curl` to the MusicBrainz endpoint fails
# - It returns 1 when the `curl` to the MusicBrainz endpoint fails
test_itDisplaysErrorAndReturns1WhenMusicBrainzRequestFails() {
  # Create a spy for curl which returns 1
  createSpy -r 1 curl

  error_output="$(coverfetch 'kero kero bonito' 'flamingo' 2>&1 >/dev/null)"

  # Verify that 1 was returned
  assertEquals 1 $?

  # Verify the expected error message was displayed to stderr
  assertEquals 'MusicBrainz endpoint failure error was not output to stderr' \
    'Failed to obtain MBID from MusicBrainz database' "$error_output"
}

# Verifies the following:
# - An error is displayed when MusicBrainz does not return the necessary MBID
# - It returns 1 when MusicBrainz does not return the necessary MBID
test_itDisplaysErrorAndReturns1WhenMusicBrainzRequestLacksMbid() {
  # Create a spy for curl which returns 0 and outputs JSON without the MBID
  createSpy -r 0 -o '{"releases":[{"score":100,"title":"Flamingo"}]}' curl

  error_output="$(coverfetch 'kero kero bonito' 'flamingo' 2>&1 >/dev/null)"

  # Verify that 1 was returned
  assertEquals 1 $?

  # Verify the expected error message was displayed to stderr
  assertEquals 'MusicBrainz endpoint failure error was not output to stderr' \
    'Failed to obtain MBID from MusicBrainz database' "$error_output"
}

# Verifies the following:
# - An error is displayed when the Cover Art Archive response status is not 200
# - It returns 2 when the Cover Art Archive response status is not 200
test_itDisplaysErrorAndReturns2WhenCoverArtArchiveResponseStatusIsNot200() {
  # Create a spy for curl
  # Call 1: Returns 0 and outputs a sample JSON response to stdout
  # Call 2: Returns 0 and outputs 404 to stdout
  createSpy -r 0 -o '{"releases":[{"id":"test-id-123","title":"Flamingo"}]}' \
    -r 0 -o '404' \
    curl

  error_output="$(coverfetch 'kero kero bonito' 'flamingo' 2>&1 >/dev/null)"

  # Verify that 2 was returned
  assertEquals 2 $?

  # Verify the expected error message was displayed to stderr
  assertEquals 'Cover Art Archive failure error was not output to stderr' \
    'Failed to download cover art from Cover Art Archive' "$error_output"
}

# Verify that usage is displayed and 1 is returned with wrong number of args
# This test doesn't need to utilize spies, but is good for full test coverage!
test_itDisplaysUsageAndReturns1WithWrongArgCount() {
  # The script should display usage and exit 1 with too few args
  output="$(coverfetch 'kero kero bonito' 2>&1)"
  assertEquals 'did not exit with status code 1 with too few args' 1 $?

  echo "$output" | grep -q 'Usage: .\+ ARTIST ALBUM'
  assertTrue 'usage was not displayed with too few args' $?

  # The script should display usage and exit 1 with too many args
  output="$(coverfetch 'kero kero bonito' 'flamingo' 'flamingo' 2>&1)"
  assertEquals 'did not exit with status code 1 with too many args' 1 $?

  echo "$output" | grep -q 'Usage: .\+ ARTIST ALBUM'
  assertTrue 'usage was not displayed with too many args' $?
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
