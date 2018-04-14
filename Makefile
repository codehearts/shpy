REPO_ROOT=$(shell git rev-parse --show-toplevel)
DOCKER_FLAGS=-it --rm -e SHUNIT_COLOR=always
KCOV_TAG=v33

TESTS=$(wildcard t/test_*)
APP_TESTS=$(addprefix /app/, $(TESTS))
WORK_TESTS=$(addprefix /work/, $(TESTS))

.PHONY: check test test_bash test_zsh coverage lint install

check: test
test: test_bash test_zsh

test_bash: docker_installed
	@$(foreach TEST, $(TESTS), \
		echo "Running $(TEST)"; \
		docker run $(DOCKER_FLAGS) \
			--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
			bash:latest bash /app/$(TEST) || exit $$?; echo;)

test_zsh: docker_installed
	@$(foreach TEST, $(TESTS), \
		echo "Running $(TEST)"; \
		docker run $(DOCKER_FLAGS) -e SHUNIT_PARENT=/rootfs/$(TEST) \
			--mount type=bind,source=$(REPO_ROOT),target=/rootfs,readonly \
			imwithye/zsh:latest zsh -o shwordsplit -c /rootfs/$(TEST) || exit $$?; echo;)

lint: docker_installed
	@docker run $(DOCKER_FLAGS) \
		--mount type=bind,source=$(REPO_ROOT),target=/work,readonly \
		manabu/checkbashisms-docker /work/shpy /work/shpy-shunit2 $(WORK_TESTS)
	@docker run $(DOCKER_FLAGS) \
		--mount type=bind,source=$(REPO_ROOT),target=/app,readonly \
		koalaman/shellcheck:latest /app/shpy /app/shpy-shunit2 $(APP_TESTS)

coverage: docker_installed
	@$(foreach TEST, $(TESTS), \
		docker run $(DOCKER_FLAGS) --security-opt seccomp=unconfined \
			--mount type=bind,source=$(REPO_ROOT),target=/source \
			ragnaroek/kcov:$(KCOV_TAG) \
			/source/coverage --exclude-path=/source/t/ /source/$(TEST) || exit $$?;)

install: docker_installed
	@docker pull bash:latest
	@docker pull imwithye/zsh:latest
	@docker pull manabu/checkbashisms-docker:latest
	@docker pull koalaman/shellcheck:latest
	@docker pull ragnaroek/kcov:$(KCOV_TAG)

docker_installed:
ifeq (, $(shell which docker))
    $(error Docker is required for testing, see https://www.docker.com to get set up)
endif
