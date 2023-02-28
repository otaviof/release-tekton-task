#!/usr/bin/env bash
#
# Installs the Tekton CLI (tkn) informed version.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

readonly INPUT_CLI_VERSION="${INPUT_CLI_VERSION:-}"

[[ -z "${INPUT_CLI_VERSION}" ]] &&
	fail "INPUT_CLI_VERSION environment variable is not set!"

readonly cli_short_version="${INPUT_CLI_VERSION//v/}"
readonly cli_tarball="tkn_${cli_short_version}_Linux_x86_64.tar.gz"
readonly cli_host_path="tektoncd/cli/releases/download/${INPUT_CLI_VERSION}"

phase "Downloading and installing Tekton (tkn) CLI '${INPUT_CLI_VERSION}'"
download_and_install ${cli_host_path} ${cli_tarball} tkn