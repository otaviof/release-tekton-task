#!/usr/bin/env bash
#
# Inspects the enviroment and create the variables consumed by the other scripts, making sure the
# mandatory configuration is present.
#

#
# GitHub Action Environment
#

# environment variables shared by default
declare -rx GITHUB_ACTOR="${GITHUB_ACTOR:-}"
declare -rx GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
declare -rx GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"

# the image tag's suffix for tekton task bundle
declare -rx INPUT_BUNDLE_TAG_SUFFIX="${INPUT_BUNDLE_TAG_SUFFIX:-}"
# github authorization token
declare -rx GITHUB_TOKEN="${GITHUB_TOKEN:-}"

for v in GITHUB_ACTOR GITHUB_TOKEN GITHUB_REPOSITORY GITHUB_REF_NAME INPUT_BUNDLE_TAG_SUFFIX; do
	[[ -z "${!v}" ]] &&
		fail "'${v}' environment variable is not set!"
done

#
# Extracting Chart Details
#

declare -r chart_yaml="Chart.yaml"

[[ ! -f "${chart_yaml}" ]] &&
	fail "File '${chart_yaml}' is not found at '${PWD}'"

declare -rx CHART_NAME="$(awk '/^name:/ { print $2 }' ${chart_yaml})"
declare -rx CHART_VERSION="$(awk '/^version:/ { print $2 }' ${chart_yaml})"

[[ -z "${CHART_NAME}" ]] &&
	fail "Unable to extract Chart's name from '${chart_yaml}'"

[[ -z "${CHART_VERSION}" ]] &&
	fail "Unable to extract Chart's version from '${chart_yaml}'"

# making sure the release tag is the same compared to the chart's version
[[ "${GITHUB_REF_NAME}" != "${CHART_VERSION}" ]] &&
	fail "Git tag '${GITHUB_REF_NAME}' and chart version '${CHART_VERSION}' must be the same!"

#
# Release Settings
#

# temporary directory for the artifacts produced by this script, using the informed location when
# available otherwise creating a new directory for each run
declare -rx BASE_DIR="${BASE_DIR:-$(mktemp -d /tmp/release.XXXXXX)}"

# github repository url where the release is taking place
declare -rx GITHUB_REPOSITORY_URL="https://github.com/${GITHUB_REPOSITORY}"

# full path to the chart tarball (tgz) and the rendered tekton task file (yaml)
declare -rx TARBALL_FILE_NAME="${CHART_NAME}-${CHART_VERSION}.tgz"
declare -rx CHART_TARBALL="${BASE_DIR}/${TARBALL_FILE_NAME}"
declare -rx TASK_FILE_NAME="${CHART_NAME}-${CHART_VERSION}.yaml"
declare -rx RENDERED_TASK_FILE="${BASE_DIR}/${TASK_FILE_NAME}"

# container registry urls
declare -rx LOCAL_REGISTRY="127.0.0.1:5000"
declare -rx TARGET_REGISTRY="ghcr.io"

# local and target registries hostname, followed by the path (namespace)
declare -rx LOCAL_REGISTRY_NAMESPACE="${LOCAL_REGISTRY}/${GITHUB_ACTOR}"
declare -rx TARGET_REGISTRY_NAMESPACE="${TARGET_REGISTRY}/${GITHUB_ACTOR}"

# helm chart fully qualified image name, for local and remote (target) container registries
declare -rx LOCAL_CHART_IMAGE_TAG="${LOCAL_REGISTRY_NAMESPACE}/${CHART_NAME}:${CHART_VERSION}"
declare -rx TARGET_CHART_IMAGE_TAG="${TARGET_REGISTRY_NAMESPACE}/${CHART_NAME}:${CHART_VERSION}"

# task bundle tag name, using the chart version and bundle tag suffix informed
declare -rx BUNDLE_TAG="${CHART_VERSION}${INPUT_BUNDLE_TAG_SUFFIX}"

# task bundle fully qualified image names, local and remote (target) registries
declare -rx LOCAL_BUNDLE_IMAGE_TAG="${LOCAL_REGISTRY_NAMESPACE}/${CHART_NAME}:${BUNDLE_TAG}"
declare -rx TARGET_BUNDLE_IMAGE_TAG="${TARGET_REGISTRY_NAMESPACE}/${CHART_NAME}:${BUNDLE_TAG}"
