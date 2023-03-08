BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

INTEGRATION_DIR ?= ./test/integration

# starts a local contianer registry to serve as a temporary location for the release artifacts
registry-start:
	docker run \
		--name="registry" \
		--rm \
		--detach \
		--publish="5000:5000" \
		--env="REGISTRY_STORAGE_DELETE_ENABLED=true" \
		docker.io/registry:2

# stops the local registry process
registry-stop:
	docker container stop registry

# run the integration tests, does not require a kubernetes instance
test-integration:
	$(BATS_CORE) $(BATS_FLAGS) $(INTEGRATION_DIR)/*.bats
