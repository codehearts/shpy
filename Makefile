PREFIX	= /usr/local
BIN	= $(DESTDIR)/$(PREFIX)/bin

.PHONY: check test install uninstall

check: test

test:
	-checkbashisms shpy shpy-shunit2
	#-shellcheck shpy shpy-shunit2
	t/test_createSpy
	t/test_getSpyCallCount
	t/test_wasSpyCalledWith
	t/test_examineNextSpyCall
	t/test_shunit2Interface
	t/test_systemCommands

install:
	cp shpy shpy-shunit2 "$(BIN)"

uninstall:
	-rm -f "$(BIN)/shpy" "$(BIN)/shpy-shunit2"
