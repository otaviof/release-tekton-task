#!/usr/bin/env bats

source ./test/helper/helper.sh

TASK_RELEASER_SH="${PWD}/task-releaser.sh"

# original helm executable location
export HELM_BIN="$(which helm)"

# mocked binaries directory
MOCK_BIN="${PWD}/test/mock/bin"

@test "should fail when the required environment variables are not set" {
	run ${TASK_RELEASER_SH}
	assert_failure
	assert_output --partial 'is not set'
}

@test "should fail when 'Chart.yaml' is not found" {
	export GITHUB_REF_NAME="0.0.1"
	export GITHUB_ACTOR="actor"
	export GITHUB_TOKEN="token"
	export INPUT_REPOSITORY_NAME="repository"

	{
		export PATH="${MOCK_BIN}:${PATH}"

		cd ${BASE_DIR}

		run ${TASK_RELEASER_SH}
		assert_failure
		assert_output --partial 'not found'

		cd -
	}
}

@test "should have a sucessful run using mocked executables" {
	export GITHUB_REF_NAME="0.0.1"
	export GITHUB_ACTOR="actor"
	export GITHUB_TOKEN="token"
	export INPUT_REPOSITORY_NAME="repository"

	cp -r ./test/mock/chart/* ${BASE_DIR}/

	{
		export PATH="${MOCK_BIN}:${PATH}"

		cd ${BASE_DIR}

		run ${TASK_RELEASER_SH}
		assert_success

		cd -
	}
}
