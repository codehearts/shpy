# shpy

*Spies and stubs for shell unit testing*

Features at a glance:

* Create spies for any command or function in the shell environment
* Stub stdout and return value of spies
* See call count and check arguments passed to the spy
* [Integrates](#shunit2-integration) with the [shunit2](https://github.com/kward/shunit2) testing framework

## API

To use **shpy** in your tests, source the `shpy` script:

	. path/to/shpy
	
A summary of functions:

Function | Description
---|---
`createSpy SPY`                 | Create a new spy, or reset an existing spy
`createSpy -r RETURN_VAL SPY`   | Sets the return value of the spy when invoked
`createSpy -o OUTPUT SPY`       | Sets output via standard output when the spy is invoked
`createStub SPY`                | Alias for `createSpy`
`getSpyCallCount SPY`           | Outputs the number of invocations of a spy
`wasSpyCalledWith SPY [ARG]...` | Verify a spy was called with the given arguments on its first invocation
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
