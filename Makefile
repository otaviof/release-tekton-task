BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration

# run the integration tests, does not require a kubernetes instance
test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats