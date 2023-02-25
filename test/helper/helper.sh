#!/usr/bin/env bats

load '../.bats/bats-support/load'
load '../.bats/bats-assert/load'
load '../.bats/bats-file/load'

# base directory to run the prepare script against, it will contain a strucuture mimicing what the
# CNB filesystem looks like
export BASE_DIR=""

function setup() {
	# creating a temporary directory before each test run below
	BASE_DIR="$(mktemp -d ${BATS_TMPDIR}/bats.XXXXXX)"

	chmod -R 0777 ${BASE_DIR}
}

function teardown() {
	rm -rfv ${BASE_DIR} || true
}
