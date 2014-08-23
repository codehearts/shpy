# shpy

*Spies and stubs for shell unit testing*

Features at a glance:

* Create spies for any command or function in the shell environment
* Stub stdout and return value of spies
* See call count and check arguments passed to the spy
* [Integrates](#shunit2-integration) with the [shunit2](http://code.google.com/p/shunit2/) testing framework

## API

To use **shpy** in your tests, source the `shpy` script:

	. path/to/shpy
	
A summary of functions:

Function                        | Description
--------------------------------|---------------------------------------------------------------------------------
`createSpy SPY`                 | create a new spy named SPY, or reset SPY if it already existed
`val=RETURN_VAL createSpy SPY`  | `createSpy` accepts an optional parameter `val`, the value that SPY returns
`output=OUTPUT createSpy SPY`   | `createSpy` accepts an optional parameter `output`, the text that SPY outputs when run
`getSpyCallCount SPY`           | output the number of times a spy has been called
`wasSpyCalledWith SPY [ARG]...` | test if a spy was called with the given arguments
`examineNextSpyCall SPY`        | tell `wasSpyCalledWith` to test on the spy's next call<br/>(by default, `wasSpyCalledwith` tests the first call to a spy — after calling `examineNextSpyCall`, `wasSpyCalledWith` will test against the second call, and so on)
`cleanupSpies`                  | after you are done testing, call this function to clean up any temporary directories created

### shunit2 Integration

To use **shpy** asserts in your **shunit2** tests, you must also source the
`shpy-shunit2` script:

	. path/to/shpy
	. path/to/shpy-shunit2
	
A summary of asserts:

Function                                     | Description
---------------------------------------------|----------------------------------------------------------------------
`assertCallCount [MESSAGE] SPY COUNT`        | asset SPY was called COUNT times
`assertCalledWith SPY [ARG]...`              | assert SPY was called with ARGs; also calls `examineNextSpyCall` so that calling `assertCalledWith` again asserts on the next call to SPY
`assertCalledWith_ MESSAGE SPY [ARG]...`     | same, but include MESSAGE in failure output
`assertCalledOnceWith SPY [ARG]...`          | convenience assert for `assertCallCount SPY 1 && assertCalledWith SPY ARGs`
`assertCalledOnceWith_ MESSAGE SPY [ARG]...` | same, but include MESSAGE in failure output

## A Word On Shell Portability

While **shunit2** remains strictly [POSIX
compliant](http://shellhaters.heroku.com/posix), **shpy** relies on [portable but more modern shell features](http://apenwarr.ca/log/?m=201102#28), such as
function-local variables.  To be clear, **shpy** does not use any
[Bashisms](https://wiki.ubuntu.com/DashAsBinSh).
