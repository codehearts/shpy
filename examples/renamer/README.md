# Example - renamer

Renames multiple files to a custom pattern with an incrementing value

```sh
renamer 'photo-*.jpg' img123.jpg img456.jpg img789.jpg
# img123.jpg -> photo-1.jpg
# img456.jpg -> photo-2.jpg
# img789.jpg -> photo-3.jpg
```

This example contains fully documented tests with 100% coverage of the `renamer` script to give you some ideas for your own projects. The rest of this document shows a simple step-by-step of how some of these tests were written using shpy

## Try It Out!

This example is included with the official [shpy image](https://hub.docker.com/r/shpy/shpy) for Docker. You can start an interactive shell with

```sh
docker run --rm -it shpy/shpy:1.0.0
```

Let's create some dummy files and run them through the renamer

```sh
touch img5678.jpg screenshot-2019-09-12.jpg untitled.jpg
/shpy/examples/renamer/renamer 'image-*.jpg' ./*.jpg
```

No output is good output, right? If you look in the directory now, you'll see the renamer worked successfully!

```sh
ls # image-1.jpg  image-2.jpg  image-3.jpg
```

## Testing renamer With Spies

Before writing tests, it's important to understand the defined behavior of the script:

- Usage is displayed with less than two arguments
- The first argument is a filename pattern string, the rest are files to rename
- The first `*` in the pattern string is replaced with an incrementing value
- The incrementing value begins at 1
- The script returns 0 when all files are renamed successfully
- If a file fails to be renamed, the script continues with the next file
- The script returns 1 when one or more files fail to rename

Now we have an idea of what to test! Let's start with renaming a single file. While we could create a temporary file on disk, let the renamer `mv` it, then verify the old file no longer exists and the new file does, this is tedious and expensive. Instead, we can use shpy to verify that `mv` was called properly since we trust `mv` to be correct

Let's begin by including shpy, the [shunit2](https://github.com/kward/shunit2) testing framework, and shpy's shunit2 integration. We'll add `renamer` to our `PATH` and write a simple test function that won't pass yet

```sh
#!/usr/bin/env sh

PATH="$PATH:/shpy/examples/renamer/"

test_itStartsPatternAt1WhenRenamingSingleFile() {
  renamer 'photo-*.jpg' img123.jpg
}

. /shpy/shpy
. /shpy/shpy-shunit2
. /usr/local/bin/shunit2
```

Running the tests fails, as expected

```
test_itStartsPatternAt1WhenRenamingSingleFile
mv: can't rename 'img123.jpg': No such file or directory
shunit2:ERROR test_itStartsPatternAt1WhenRenamingSingleFile() returned non-zero return code.

Ran 1 test.

FAILED (failures=1)
```

The test output shows that `mv` failed because the file to rename does not exist. Rather than creating this file, let's create a spy for `mv` and verify that `img123.jpg` is moved to `photo-1.jpg`

```sh
test_itStartsPatternAt1WhenRenamingSingleFile() {
  createSpy mv

  renamer 'photo-*.jpg' img123.jpg

  assertCalledWith_ 'file was not renamed correctly' mv img123.jpg photo-1.jpg
}
```

Sweet, the tests pass now!

```
test_itStartsPatternAt1WhenRenamingSingleFile

Ran 1 test.

OK
```

How do we know the verification is actually working, though? Let's change the expected target filename to `fail.jpg` and see what happens

```sh
test_itStartsPatternAt1WhenRenamingSingleFile() {
  createSpy mv

  renamer 'photo-*.jpg' img123.jpg

  assertCalledWith_ 'file was not renamed correctly' mv img123.jpg fail.jpg
}
```

Ahah! Changing our expectation broke the test, so shpy really is verifying the call to `mv`

```
test_itStartsPatternAt1WhenRenamingSingleFile
ASSERT:file was not renamed correctly
shunit2:ERROR test_itStartsPatternAt1WhenRenamingSingleFile() returned non-zero return code.

Ran 1 test.

FAILED (failures=2)
```

From here, we can easily write another test for renaming two files

```sh
test_itStartsPatternAt2WhenRenamingTwoFiles() {
  createSpy mv

  renamer 'photo-*.jpg' img123.jpg img456.jpg

  examineNextSpyCall mv # skip the first call to mv, the previous test covered it
  assertCalledWith_ 'second file was not renamed correctly' mv img456.jpg photo-2.jpg
}
```

Piece of cake, they both pass!

```
test_itStartsPatternAt1WhenRenamingSingleFile
test_itStartsPatternAt2WhenRenamingTwoFiles

Ran 2 tests.

OK
```

While spies help to avoid setting up system resources, they're also useful for testing edge cases. One of `renamer`'s behaviors is to continue renaming if a `mv` fails. Making `mv` fail intermittently sounds like a headache, but shpy can do this easily

```sh
test_itContinuesWhenFileFailsToRename() {
  createSpy -r 0 -r 1 -r 0 mv # mv will return 1 on the second call only

  renamer 'photo-*.jpg' img123.jpg img456.jpg img789.jpg

  assertCalledWith_ '1st file was not renamed correctly' mv img123.jpg photo-1.jpg
  assertCalledWith_ '2nd file was not renamed correctly' mv img456.jpg photo-2.jpg
  assertCalledWith_ '3rd file was not renamed correctly after 2nd rename failed' \
    mv img789.jpg photo-3.jpg
}
```

_Et voila,_ three passing tests!

```
test_itStartsPatternAt1WhenRenamingSingleFile
test_itStartsPatternAt2WhenRenamingTwoFiles
test_itContinuesWhenFileFailsToRename

Ran 3 tests.

OK
```

That's all it takes! We didn't need temporary files to make these tests possibly, we just needed spies :mag:
