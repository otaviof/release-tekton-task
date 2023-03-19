#!/usr/bin/env bash
#
# Packages and release the informed Tekton Task repository using the Helm-Chart structure as the
# scaffold for the # packaging mechanism.
#
# The Chart version must be the same than the GITHUB_REF_NAME (release's tag), in other words the
# GitHub Release must match the Chart version for consistency.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

#
# Inputs
#

phase "Loading configuration from environment variables"

# environment variables shared by github actions
readonly GITHUB_ACTOR="${GITHUB_ACTOR:-}"
readonly GITHUB_TOKEN="${GITHUB_TOKEN:-}"
readonly GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
readonly GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"

# the image tag's suffix for tekton task bundle
readonly INPUT_BUNDLE_TAG_SUFFIX="${INPUT_BUNDLE_TAG_SUFFIX:-}"

for v in GITHUB_ACTOR GITHUB_TOKEN GITHUB_REPOSITORY GITHUB_REF_NAME INPUT_BUNDLE_TAG_SUFFIX; do
	[[ -z "${!v}" ]] &&
		fail "'${v}' environment variable is not set!"
done

# temporary directory for the artifacts produced by this script, using the informed location when
# available otherwise creating a new directory each run
readonly BASE_DIR="${BASE_DIR:-$(mktemp -d /tmp/release-tekton-task.XXXXXX)}"

#
# Variables
#

# temporary container registry URL
readonly local_registry="127.0.0.1:5000"
# permanent container registry URL
readonly target_registry="ghcr.io"

# default location for the chart metadata file
readonly chart_yaml="Chart.yaml"

[[ ! -f "${chart_yaml}" ]] &&
	fail "File '${chart_yaml}' is not found at '${PWD}'"

# chart name and version will be extrated later on
chart_name=""
chart_version=""

#
# Functions
#

# extracts the chart's name and version from the manifest file, setting the results on the readonly
# predefined global variables, and assert the chart version is the same than GITHUB_REF_NAME
function extract_chart_name_version() {
	readonly chart_name="$(awk '/^name:/ { print $2 }' ${chart_yaml})"
	readonly chart_version="$(awk '/^version:/ { print $2 }' ${chart_yaml})"

	[[ -z "${chart_name}" ]] &&
		fail "'chart_name' can't be otainted from '${chart_yaml}'"

	[[ -z "${chart_version}" ]] &&
		fail "'chart_version' can't be otainted from ${chart_yaml}"

	[[ "${GITHUB_REF_NAME}" != "${chart_version}" ]] &&
		fail "Git tag '${GITHUB_REF_NAME}' and chart version '${chart_version}' must be the same!"

	return 0
}

# packages the local helm chart using `helm package`, using as destination directory the `dirname` of
# the informed chart taball path, after packaging the chart tarball asserts the file exists
function package_helm_chart() {
	local _chart_tarball="${1}"
	local _destination_dir="$(dirname ${chart_tarball})"

	helm package --destination="${_destination_dir}" . >/dev/null

	[[ ! -f "${_chart_tarball}" ]] &&
		fail "'${_chart_tarball}' is not found!"

	return 0
}

# renders the task file resource using `helm template`, and then asserts the rendered file exists
function render_helm_chart_template() {
	local _destination="${1}"

	helm template . >${_destination}

	[[ ! -f "${_destination}" ]] &&
		fail "Rendered task file is not found at '${_destination}'!"

	return 0
}

# uses crane to set the repository reference as image's annotation, the GitHub container registry can
# link the image with the respective project using the reference
function set_image_annotations() {
	local _repository="https://github.com/${GITHUB_REPOSITORY}"
	crane mutate --annotation="org.opencontainers.image.source=${_repository}" ${1}
}

# creates the helm chart container image using `helm push`, which creates a image using the
# chart-name as the image name, and chart-version as tag. That's a Helm convention enforced to
# install the chart via container image.
function create_helm_chart_image() {
	local _chart_tarball="${1}"
	local _registry_namespace="${2}"
	local _target_tag="${3}"

	helm push ${_chart_tarball} "oci://${_registry_namespace}"
	set_image_annotations "${_registry_namespace}/${chart_name}:${_target_tag}"
}

# creates the tekton task bundle container image, setting the regular annotations right after
function create_task_bundle_image() {
	local _task_file="${1}"
	local _image_tag="${2}"

	tkn bundle push ${_image_tag} --filenames="${_task_file}"
	set_image_annotations ${_image_tag}
}

#
# Main
#

# inspecting the current directory to extract chart's name and version
phase "Extracting Chart's name and version ('${chart_yaml}')"
extract_chart_name_version

# full path to the expected helm chart tarball
readonly chart_tarball="${BASE_DIR}/${chart_name}-${chart_version}.tgz"

phase "Packaging Helm-Chart '${chart_name}-${chart_version}' ('${BASE_DIR}')"
package_helm_chart ${chart_tarball}

phase "Helm-Chart package contents '${chart_tarball}'"
tar -ztvpf ${chart_tarball}

# full path to the expected rendered task resource file
readonly target_file="${BASE_DIR}/${chart_name}-${chart_version}.yaml"

phase "Rendering template on a single Task file '${target_file}'"
render_helm_chart_template ${target_file}
ls -lh ${target_file}

# local and target registries hostname, followed by the path (namespace)
readonly local_registry_namespace="${local_registry}/${GITHUB_ACTOR}"
readonly target_registry_namespace="${target_registry}/${GITHUB_ACTOR}"

# helm chart fully qualified image name, for local and remote (target) container registries
readonly local_chart_image_tag="${local_registry_namespace}/${chart_name}:${chart_version}"
readonly target_chart_image_tag="${target_registry_namespace}/${chart_name}:${chart_version}"

phase "Creating Helm-Chart image '${local_chart_image_tag}'"
create_helm_chart_image ${chart_tarball} ${local_registry_namespace} ${chart_version}

# task bundle tag name, using the chart version and bundle tag suffix informed
readonly bundle_tag="${chart_version}${INPUT_BUNDLE_TAG_SUFFIX}"

# task bundle fully qualified image names, local and remote (target) registries
readonly local_bundle_image_tag="${local_registry_namespace}/${chart_name}:${bundle_tag}"
readonly target_bundle_image_tag="${target_registry_namespace}/${chart_name}:${bundle_tag}"

phase "Creating Tekton Task Bundle image '${local_bundle_image_tag}'"
create_task_bundle_image ${target_file} ${local_bundle_image_tag}

phase "Uploading Tekton Task and Helm-Chart package to release '${GITHUB_REF_NAME}'"
gh release upload --clobber ${GITHUB_REF_NAME} ${target_file} ${chart_tarball}

phase "Logging in the Container-Registry '${target_registry}' ('${GITHUB_ACTOR}')"
crane auth login --username="${GITHUB_ACTOR}" --password-stdin ${target_registry} <<<${GITHUB_TOKEN}

phase "Pushing Tekton Task Bundle container image '${target_bundle_image_tag}'"
crane copy ${local_bundle_image_tag} ${target_bundle_image_tag}

phase "Pushing Helm-Chart container image '${target_chart_image_tag}'"
crane copy ${local_chart_image_tag} ${target_chart_image_tag}

# removing temporary directoy only when it has been created by this script, using the temporary
# directory patter informed to mktemp early on
if [[ "${BASE_DIR}" == *"release-tekton-task"* ]]; then
	phase "Cleaning up temporary directory ('${BASE_DIR}')"
	rm -rf ${BASE_DIR}
fi
