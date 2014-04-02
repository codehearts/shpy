PREFIX	= /usr/local
BIN	= $(DESTDIR)/$(PREFIX)/bin

.PHONY: check test install uninstall

check: test

test:
	-checkbashisms shpy shpy-shunit2
	#-shellcheck shpy shpy-shunit2
	"$(SHELL)" t/test_createSpy
	"$(SHELL)" t/test_getSpyCallCount
	"$(SHELL)" t/test_wasSpyCalledWith
	"$(SHELL)" t/test_examineNextSpyCall
	"$(SHELL)" t/test_shunit2Interface
	"$(SHELL)" t/test_systemCommands

install:
	cp shpy shpy-shunit2 "$(BIN)"

uninstall:
	-rm -f "$(BIN)/shpy" "$(BIN)/shpy-shunit2"
