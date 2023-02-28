#!/usr/bin/env bash
#
# Inspect the instance to make sure the dependencies are in place.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

probe_bin_on_path "cr"
probe_bin_on_path "gh"
probe_bin_on_path "helm"
probe_bin_on_path "tar"
probe_bin_on_path "tkn"
