#!/usr/bin/env bats

source ./test/helper/helper.sh

task_releaser_sh="${PWD}/release.sh"

# original helm executable location
export HELM_BIN="$(which helm)"

# mocked binaries directory
mock_bin="${PWD}/test/mock/bin"

@test "should fail when the required environment variables are not set" {
	unset GITHUB_REF_NAME

	run ${task_releaser_sh}
	assert_failure
	assert_output --partial 'is not set'
}

@test "should fail when 'Chart.yaml' is not found" {
	export GITHUB_ACTOR="actor"
	export GITHUB_TOKEN="token"
	export GITHUB_REF_NAME="0.0.1"
	export GITHUB_REPOSITORY="org/repo"

	export INPUT_BUNDLE_TAG_SUFFIX="-bundle"

	{
		export PATH="${mock_bin}:${PATH}"

		cd ${BASE_DIR}

		run ${task_releaser_sh} >&3
		assert_failure
		assert_output --partial 'not found'

		cd -
	}
}

@test "should have a sucessful run using mocked executables" {
	export GITHUB_ACTOR="actor"
	export GITHUB_TOKEN="token"
	export GITHUB_REF_NAME="0.0.1"
	export GITHUB_REPOSITORY="org/repo"

	export INPUT_BUNDLE_TAG_SUFFIX="-bundle"

	cp -r ./test/mock/chart/* ${BASE_DIR}/

	{
		export PATH="${mock_bin}:${PATH}"

		cd ${BASE_DIR}

		run ${task_releaser_sh} >&3
		assert_success

		cd -
	}
}
