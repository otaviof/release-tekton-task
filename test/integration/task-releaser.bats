#!/usr/bin/env bats

source ./test/helper/helper.sh

task_releaser_sh="${PWD}/task-releaser.sh"

# original helm executable location
export HELM_BIN="$(which helm)"

# mocked binaries directory
mock_bin="${PWD}/test/mock/bin"

@test "should fail when the required environment variables are not set" {
	run ${task_releaser_sh}
	assert_failure
	assert_output --partial 'is not set'
}

@test "should fail when 'Chart.yaml' is not found" {
	export GITHUB_REF_NAME="0.0.1"
	export GITHUB_ACTOR="actor"
	export GITHUB_TOKEN="token"
	export INPUT_REPOSITORY_NAME="repository"
	export INPUT_BUNDLE_SUFFIX="-bundle"

	{
		export PATH="${mock_bin}:${PATH}"

		cd ${BASE_DIR}

		run ${task_releaser_sh}
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
	export INPUT_BUNDLE_SUFFIX="-bundle"

	cp -r ./test/mock/chart/* ${BASE_DIR}/

	{
		export PATH="${mock_bin}:${PATH}"

		cd ${BASE_DIR}

		run ${task_releaser_sh}
		assert_success

		cd -
	}
}
