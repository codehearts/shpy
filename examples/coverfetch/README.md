# Example - coverfetch

Fetches cover art from the Cover Art Archive and MusicBrainz databases

```sh
coverfetch 'kero kero bonito' 'flamingo'
```

This example contains fully documented tests with 100% coverage of the `coverfetch` script to give you some ideas for your own projects. The rest of this document shows a simple step-by-step of how some of these tests were written using shpy

## Try It Out!

This example is included with the official [shpy image](https://hub.docker.com/r/shpy/shpy) for Docker. You can start an interactive shell which will save the cover art to `./coverfetch-test/cover.png` on your local machine with

```sh
docker run --rm -it -v"$PWD/coverfetch-test":/app shpy/shpy:1.0.0
```

Let's download the artwork for _Tokyo Shoegazer's_ album _Crystallize_ (or you can try it out with your favorite album)

```sh
/shpy/examples/coverfetch/coverfetch '東京酒吐座' 'crystallize'
```

If everything went well, you should have a new `./coverfetch-test/cover.png` file on your local machine with the album's cover art!

## Testing coverfetch With Spies

Before writing tests, it's important to understand the defined behavior of the script:

- Usage is displayed when there are not exactly two arguments
- The first argument is the artist's name, the second is the album name
- The cover artwork is downloaded to `./cover.png` usig `curl`
- The script returns 1 when it fails to obtain the MusicBrainz ID for the album
- The script returns 2 when it fails to download the artwork from the Cover Art Archive

Now we have an idea of what to test! Let's start with a failed fetch of the MusicBrainz ID. Causing `curl` to fail by calling `coverfetch` would be tricky, but `shpy` make this simple

Let's begin by including shpy, the [shunit2](https://github.com/kward/shunit2) testing framework, and shpy's shunit2 integration. We'll add `coverfetch` to our `PATH` and write a simple test function that won't pass yet

```sh
#!/usr/bin/env sh

PATH="$PATH:/shpy/examples/coverfetch/"

test_itReturns1WhenMusicBrainzRequestFails() {
  coverfetch 'kero kero bonito' 'flamingo' >/dev/null 2>&1

  assertEquals 1 $?
}

. /shpy/shpy
. /shpy/shpy-shunit2
. /usr/local/bin/shunit2
```

Running the tests fails, as expected

```
test_itReturns1WhenMusicBrainzRequestFails
ASSERT:expected:<1> but was:<0>
shunit2:ERROR test_itReturns1WhenMusicBrainzRequestFails() returned non-zero return code.

Ran 1 test.

FAILED (failures=2)
```

The output says the test failed because `coverfetch` did not return 1, so let's make `curl` fail and see what happens! To do this, we'll need to create a spy

```sh
test_itReturns1WhenMusicBrainzRequestFails() {
  createSpy -r 1 curl

  coverfetch 'kero kero bonito' 'flamingo' >/dev/null 2>&1

  assertEquals 1 $?
}
```

Sweet, the tests pass now!

```
test_itReturns1WhenMusicBrainzRequestFails

Ran 1 test.

OK
```

From here, we can write another test to verify it returns 2 when the Cover Art Archive download fails. The first call to `curl` will return 0 and output a valid response snippet containing the MusicBrainz ID, while the second call will return 1 and output nothing

```sh
test_itReturns2WhenCoverArtArchiveRequestFails() {
  createSpy -r 0 -o '{"releases":[{"id":"test-id-123","title":"Flamingo"}]}' \
    -r 1 -o '' \
    curl

  coverfetch 'kero kero bonito' 'flamingo' >/dev/null 2>&1

  assertEquals 2 $?
}
```

Piece of cake, they both pass!

```
test_itReturns1WhenMusicBrainzRequestFails
test_itReturns2WhenCoverArtArchiveRequestFails

Ran 2 tests.

OK
```

Now that we've covered some of the failure cases, let's test a successful download. We can assume the implementation of `curl` is correct, and instead focus on how our script calls it. As long as we call the Cover Art Archive endpoint with the MBID and tell curl to save the output to `./cover.png`, we can be reasonably sure the script is working correctly

```sh
test_itUsesMusicBrainzIdToDownloadCoverArt() {
  createSpy -r 0 -o '{"releases":[{"id":"test-id-123","title":"Flamingo"}]}' \
    -r 0 -o '200' \
    curl

  coverfetch 'kero kero bonito' 'flamingo'

  # Verify the first curl call contained the artist/album query
  getArgsForCall curl 1 | grep -q "query=artist:'kero kero bonito' AND release:'flamingo'"
  assertTrue 'MusicBrainz API endpoint was not queried' $?

  # Verify the second curl call contained the MBID in the endpoint request
  getArgsForCall curl 2 | grep -q 'http://coverartarchive.org/release/test-id-123/front-500.png'
  assertTrue 'Cover Art Archive API endpoint was not called with MBID' $?

  # Verify the second curl call output the response to `./cover.png`
  getArgsForCall curl 2 | grep -q -- '--output cover.png'
  assertTrue 'Cover Art Archive API endpoint response was not saved to ./cover.png' $?
}
```

There we go, three passing tests!

```
test_itReturns1WhenMusicBrainzRequestFails
test_itReturns2WhenCoverArtArchiveRequestFails
test_itUsesMusicBrainzIdToDownloadCoverArt

Ran 3 tests.

OK
```

Testing scripts that access the network can seem daunting, but shpy helps simplify the process in a reliable, offline manner. While there's no substitute for integration tests that make use of the actual network, unit tests with spies run faster and make it easier to test with specific endpoint responses and request failures :globe_with_meridians: :ballot_box_with_check:
