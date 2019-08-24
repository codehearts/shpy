# shpy
Spies and stubs for shell unit testing

| POSIX Compliance | Bash | Dash | Sh | Zsh | Coverage | License |
| :--------------: | :--: | :--: | -- | :-: | :------: | :-----: |
[![Build Status][lint-build-badge]][build-link] | [![Build Status][bash-build-badge]][build-link] | [![Build Status][dash-build-badge]][build-link] | [![Build Status][sh-build-badge]][build-link] | [![Build Status][zsh-build-badge]][build-link] | [![Coverage][coverage-badge]][coverage-link] | [![MIT License][license-badge]](LICENSE.md) |

Features at a glance:

* Create spies for any command or function in the shell environment
* Stub stdout and return value of spies
* See call count and check arguments passed to the spy
* [Integrates](#shunit2-integration) with the [shunit2](https://github.com/kward/shunit2) testing framework

## Contributing

If you'd like to help with shpy's development, or just gain a better understanding of how it's managed, check out the [CONTRIBUTING.md](CONTRIBUTING.md)

## API

To use **shpy** in your tests, source the `shpy` script:

	. path/to/shpy
	
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

To use **shpy** asserts in your **shunit2** tests, you must also source the
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

Use the `oneTimeTearDown` hook provided by **shunit2** to clean up any spies:

    oneTimeTearDown() {
        cleanupSpies
    }

## A Word On Shell Portability

While **shunit2** remains strictly [POSIX
compliant](http://shellhaters.herokuapp.com/posix), **shpy** relies on [portable but more modern shell features](http://apenwarr.ca/log/?m=201102#28), such as
function-local variables.  To be clear, **shpy** does not use any
[Bashisms](https://wiki.ubuntu.com/DashAsBinSh).

[coverage-badge]:   https://codecov.io/gh/codehearts/shpy/branch/master/graph/badge.svg
[coverage-link]:    https://codecov.io/gh/codehearts/shpy
[license-badge]:    https://img.shields.io/badge/license-MIT-007EC7.svg
[build-badge]:      https://travis-ci.org/codehearts/shpy.svg?branch=master
[lint-build-badge]: https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/1
[bash-build-badge]: https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/2
[dash-build-badge]: https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/3
[sh-build-badge]:   https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/4
[zsh-build-badge]:  https://travis-matrix-badges.herokuapp.com/repos/codehearts/shpy/branches/master/5
[build-link]:       https://travis-ci.org/codehearts/shpy
