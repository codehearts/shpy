# shpy

[![Build Status][build-badge]][build-link]
[![Coverage][coverage-badge]][coverage-link]
[![MIT License][license-badge]](https://github.com/codehearts/shpy/blob/master/LICENSE.md)

POSIX compliant<sup>*</sup> spies and stubs for shell unit testing

| ash | bash | mksh | zsh |
| :-: | :--: | :--: | :-: |
| [![Ash Build Status][ash-build-badge]][build-link] | [![Bash Build Status][bash-build-badge]][build-link] | [![Mksh Build Status][mksh-build-badge]][build-link] | [![Zsh Build Status][zsh-build-badge]][build-link] |

Features at a glance:

- Create spies for any command or function in the shell environment
- Stub the stdout, stderr, and return value of spies
- See the call count and check arguments passed to spies
- [Integrates](#shunit2-integration) with the [shunit2](https://github.com/kward/shunit2) testing framework

## Table of Contents

- [Why Unit Test Shell Scripts?](#why-unit-test-shell-scripts)
- [Docker Image](#docker-image)
- [Usage](#usage)
- [Contributing](#contributing)
- [API Reference](#api-reference)
  - [shunit2 Integration](#shunit2-integration)
- [A Word On Shell Portability](#a-word-on-shell-portability)

## Why Unit Test Shell Scripts?

Like other scripting languages, shell scripts can become complex and difficult to maintain over time. Unit tests help to avoid regressions and verify the correctness of functionality, but where do spies come in?

Spies are useful for limiting the dependencies and scope of a test. Code that utilizes system binaries or shell functions can be tested without running the underlying implementations, allowing tests to focus solely on the system under test. To see this in action, see [examples/renamer](https://github.com/codehearts/shpy/blob/master/examples/renamer)

The benefits of spies are even greater when testing code that relies on a network. For an example of using spies to stub `curl` and make unit tests completely offline, see [examples/coverfetch](https://github.com/codehearts/shpy/blob/master/examples/coverfetch)

## Docker Image

Shpy is available as [shpy/shpy](https://hub.docker.com/r/shpy/shpy) on Docker Hub. The latest master node is published as `shpy/shpy:latest`, while tagged releases are available as `shpy/shpy:1.0.0`. To use `kcov`, append `-kcov` to the tag or use the `kcov` tag for the latest master node

To use the shpy image, mount your code into `/app` and specify the command you want to run

```sh
docker --rm -v$PWD:/app:ro shpy/shpy:1.0.0 zsh /app/tests/run_my_tests.sh
#           ^-your project                 ^--------your command---------
```

The following scripts and binaries are provided by this image

| Name | Type | Location |
| :--- | :--- | :------- |
| shpy | script |  `/shpy/shpy` |
| shpy-shunit2 | script | `/shpy/shpy-shunit2` |
| shunit2 | script | `/usr/local/bin/shunit2` |
| ash | binary | `/bin/sh` |
| bash | binary | `/bin/bash` |
| checkbashisms | binary | `/usr/bin/checkbashisms` |
| mksh | binary | `/bin/mksh` |
| shellcheck | binary | `/usr/local/bin/shellcheck` |
| zsh | binary | `/bin/zsh` |

## Usage

Let's try out shpy! If you don't want to install shpy locally you can run the official [Docker](https://www.docker.com) image like so:

```sh
docker run -it --rm shpy/shpy:1.0.0
```

To use shpy, the `SHPY_PATH` environment variable must be set as the path to shpy and the shpy script must be sourced. If you're using the Docker image, `SHPY_PATH` is already set and shpy is located at `/shpy/shpy`

```sh
SHPY_PATH=path/to/shpy
. path/to/shpy
```

Let's create a spy for the `touch` command and call it!

```sh
createSpy touch
touch my-new-file
ls my-new-file # No such file or directory, touch wasn't actually called
```

The call to `touch` was _stubbed out_ with a test dummy in place of the actual implementation. Spies record data about the calls made to them, allowing you to check the call count or call args

```sh
getSpyCallCount touch # 1
wasSpyCalledWith touch my-new-file # true
wasSpyCalledWith touch my-old-file # false
getArgsForCall touch 1 # my-new-file
```

Spies can also simulate successful or unsuccessful calls, like so:

```sh
createSpy -o 'call me once, shame on you' -e '' -r 0 \
          -e 'call me twice, shame on me' -o '' -r 1 touch
touch my-new-file # outputs "call me once, shame on you" to stdout, returns true
touch my-new-file # outputs "call me twice, shame on me" to stderr, returns false
```

When you're done playing with shpy, it's only polite to clean up after yourself

```sh
cleanupSpies
touch my-new-file
ls my-new-file # my-new-file, touch was actually called!
```

Your shell environment is back to normal, and you've got a new tool at your disposal! :mortar_board:

## Contributing

If you'd like to help with shpy's development, or just gain a better understanding of the internals, check out the [contributor guidelines](https://github.com/codehearts/shpy/blob/master/CONTRIBUTING.md)

## API Reference

To use shpy in your tests, set `SHPY_PATH` to the location of `shpy` and source the script:

```
SHPY_PATH=path/to/shpy
export SHPY_PATH

. path/to/shpy
```

When using the Docker image, `SHPY_PATH` is preset as `/shpy/shpy` for convenience
	
A summary of functions:

Function | Description
---|---
`createSpy SPY`                 | Create a new spy, or reset an existing spy
`createSpy -r RETURN_VAL SPY`   | Sets the return value of the spy when invoked<br>Can be passed multiple times to set a return value sequence<br>Once the sequence finishes, the last value is always returned
`createSpy -o OUTPUT SPY`       | Sets output via standard output when the spy is invoked<br>Can be passed multiple times to set an output sequence<br>Once the sequence finishes, the last value is always output<br>When used with `-e`, standard out is written to first
`createSpy -e OUTPUT SPY`       | Sets output via standard error when the spy is invoked<br>Can be passed multiple times to set an error output sequence<br>Once the sequence finishes, the last value is always output<br>When used with `-o`, standard out is written to first
`createStub SPY`                | Alias for `createSpy`
`getSpyCallCount SPY`           | Outputs the number of invocations of a spy
`wasSpyCalledWith SPY [ARG]...` | Verify a spy was called with the given arguments on its first invocation
`getArgsForCall SPY NUM`        | Outputs the arguments from an invocation of a spy (first call is 1)<br>Single-word arguments are always listed without quotes<br>Multi-word arguments are always listed with double-quotes
`examineNextSpyCall SPY`        | Advances the invocation to check when calling `wasSpyCalledWith`<br>This causes `wasSpyCalledWith` to verify the second invocation, etc
`cleanupSpies`                  | Clean up any temporary directories created for spies

### shunit2 Integration

To use shpy asserts in your shunit2 tests, you must also source the
`shpy-shunit2` script:

	. path/to/shpy
	. path/to/shpy-shunit2
	
A summary of asserts:

Function                                              | Description
------------------------------------------------------|------------------------------------------------------------------
`assertCallCount [MESSAGE] SPY COUNT`        | Assert the number of times the spy was invoked
`assertCalledWith SPY [ARG]...`              | Assert the arguments for the first invocation of the spy<br>Subsequent calls will assert for the second invocation, etc
`assertCalledWith_ MESSAGE SPY [ARG]...`     | Same as `assertCalledWith`, with a specific assertion message
`assertCalledOnceWith SPY [ARG]...`          | Assert the spy was called once and given the specified arguments
`assertCalledOnceWith_ MESSAGE SPY [ARG]...` | Same as `assertCalledOnceWith`, with a specific assertion message
`assertNeverCalled [MESSAGE] SPY`            | Assert the spy was never invoked

Use the `tearDown` hook provided by shunit2 to remove all spies after each test

```sh
tearDown() {
  cleanupSpies
}
```

## A Word On Shell Portability

shpy relies on [portable but more modern shell features](http://apenwarr.ca/log/?m=201102#28), such as the `local` keyword. To be clear, shpy does not use any [Bashisms](https://wiki.ubuntu.com/DashAsBinSh)

[coverage-badge]:   https://codecov.io/gh/codehearts/shpy/branch/master/graph/badge.svg
[coverage-link]:    https://codecov.io/gh/codehearts/shpy
[license-badge]:    https://img.shields.io/badge/license-MIT-007EC7.svg
[build-badge]:      https://travis-ci.org/codehearts/shpy.svg?branch=master
[ash-build-badge]:  https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/1
[bash-build-badge]: https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/2
[mksh-build-badge]: https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/4
[zsh-build-badge]:  https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/6
[build-link]:       https://travis-ci.org/codehearts/shpy
