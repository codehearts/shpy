REPO_ROOT=$(shell git rev-parse --show-toplevel)
DOCKER_FLAGS=-it --rm -e SHUNIT_COLOR=always
KCOV_TAG=v33

TESTS=$(wildcard t/test_*)
APP_TESTS=$(addprefix /app/, $(TESTS))
WORK_TESTS=$(addprefix /work/, $(TESTS))

.PHONY: check test test_bash test_dash test_sh test_zsh coverage lint install

check: test
test: test_bash test_dash test_sh test_zsh

test_bash: docker_installed
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/bash \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		debian:latest /bin/bash /app/t/run_tests

test_dash: docker_installed
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/dash \
		--mount type=bind,source=$(REPO_ROOT),target=/rootfs,readonly \
		debian:latest /bin/dash -c /rootfs/t/run_tests

test_sh: docker_installed
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/sh \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		debian:latest /bin/sh -c /app/t/run_tests

test_zsh: docker_installed
	@docker run $(DOCKER_FLAGS) -e SHELL=/bin/zsh \
		--mount type=bind,source=$(REPO_ROOT),target=/rootfs,readonly \
		imwithye/zsh:latest /bin/zsh -o shwordsplit -c /rootfs/t/run_tests

lint: docker_installed
	@docker run $(DOCKER_FLAGS) \
		--mount type=bind,source=$(REPO_ROOT),target=/work,readonly \
		manabu/checkbashisms-docker /work/shpy /work/shpy-shunit2 /work/t/run_tests $(WORK_TESTS)
	@docker run $(DOCKER_FLAGS) \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		koalaman/shellcheck:latest /app/shpy /app/shpy-shunit2 /app/t/run_tests $(APP_TESTS)

coverage: docker_installed
	@docker run $(DOCKER_FLAGS) --security-opt seccomp=unconfined \
		-e SHELL=/bin/bash -e USE_KCOV=true \
		--mount type=bind,source=$(REPO_ROOT),target=/source \
		--entrypoint=/source/t/run_tests ragnaroek/kcov:$(KCOV_TAG)

install: docker_installed
	@docker pull debian:latest
	@docker pull imwithye/zsh:latest
	@docker pull manabu/checkbashisms-docker:latest
	@docker pull koalaman/shellcheck:latest
	@docker pull ragnaroek/kcov:$(KCOV_TAG)

docker_installed:
ifeq (, $(shell which docker))
    $(error Docker is required for testing, see https://www.docker.com to get set up)
endif
