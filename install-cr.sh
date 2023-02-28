#!/usr/bin/env bash
#
# Installs the Tekton CLI (tkn) informed version.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

readonly INPUT_CR_VERSION="${INPUT_CR_VERSION:-}"

[[ -z "${INPUT_CR_VERSION}" ]] &&
	fail "INPUT_CR_VERSION environment variable is not set!"

readonly cr_short_version="${INPUT_CR_VERSION//v/}"
readonly cr_tarball="chart-releaser_${cr_short_version}_linux_amd64.tar.gz"
readonly cr_host_path="helm/chart-releaser/releases/download/${INPUT_CR_VERSION}"

phase "Downloading and installing Helm Chart-Releaser (cr) CLI '${INPUT_CR_VERSION}'"
download_and_install ${cr_host_path} ${cr_tarball} cr