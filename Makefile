REPO_ROOT=$(shell git rev-parse --show-toplevel)
DOCKER_FLAGS=-it --rm -e SHUNIT_COLOR=always

DOCKER_DEBIAN=debian:latest
DOCKER_ZSH=imwithye/zsh:latest
DOCKER_CHECKBASHISMS=manabu/checkbashisms-docker:latest
DOCKER_SHELLCHECK=koalaman/shellcheck:latest
DOCKER_KCOV=ragnaroek/kcov:v33

TESTS=$(wildcard t/test_*)
APP_TESTS=$(addprefix /app/, $(TESTS))
WORK_TESTS=$(addprefix /work/, $(TESTS))

.PHONY: check test test_bash test_dash test_sh test_zsh coverage lint

check: test
test: test_bash test_dash test_sh test_zsh

test_bash: docker_installed
ifeq (, $(shell docker images -q $(DOCKER_DEBIAN)))
	@docker pull $(DOCKER_DEBIAN)
endif
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/bash \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		$(DOCKER_DEBIAN) /bin/bash /app/t/run_tests

test_dash: docker_installed
ifeq (, $(shell docker images -q $(DOCKER_DEBIAN)))
	@docker pull $(DOCKER_DEBIAN)
endif
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/dash \
		--mount type=bind,source=$(REPO_ROOT),target=/rootfs,readonly \
		$(DOCKER_DEBIAN) /bin/dash -c /rootfs/t/run_tests

test_sh: docker_installed
ifeq (, $(shell docker images -q $(DOCKER_DEBIAN)))
	@docker pull $(DOCKER_DEBIAN)
endif
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/sh \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		$(DOCKER_DEBIAN) /bin/sh -c /app/t/run_tests

test_zsh: docker_installed
ifeq (, $(shell docker images -q $(DOCKER_ZSH)))
	@docker pull $(DOCKER_ZSH)
endif
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/zsh \
		--mount type=bind,source=$(REPO_ROOT),target=/rootfs,readonly \
		$(DOCKER_ZSH) /bin/zsh -o shwordsplit -c /rootfs/t/run_tests

lint: docker_installed
ifeq (, $(shell docker images -q $(DOCKER_CHECKBASHISMS)))
	@docker pull $(DOCKER_CHECKBASHISMS)
endif
ifeq (, $(shell docker images -q $(DOCKER_SHELLCHECK)))
	@docker pull $(DOCKER_SHELLCHECK)
endif
	@docker run $(DOCKER_FLAGS) \
		--mount type=bind,source=$(REPO_ROOT),target=/work,readonly \
		$(DOCKER_CHECKBASHISMS) /work/shpy /work/shpy-shunit2 \
		/work/t/run_tests $(WORK_TESTS)
	@docker run $(DOCKER_FLAGS) \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		$(DOCKER_SHELLCHECK) /app/shpy /app/shpy-shunit2 \
		/app/t/run_tests $(APP_TESTS)

coverage: docker_installed
ifeq (, $(shell docker images -q $(DOCKER_KCOV)))
	@docker pull $(DOCKER_KCOV)
endif
	@docker run $(DOCKER_FLAGS) --security-opt seccomp=unconfined \
		-e SHELL=/bin/bash -e USE_KCOV=true \
		--mount type=bind,source=$(REPO_ROOT),target=/source \
		--entrypoint=/source/t/run_tests $(DOCKER_KCOV)

docker_installed:
ifeq (, $(shell which docker))
	$(error Docker is required for testing, see https://www.docker.com to get set up)
endif
