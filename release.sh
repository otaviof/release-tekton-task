#!/usr/bin/env bash
#
# Packages and release the informed Tekton Task repository using the Helm-Chart structure as the
# scaffold for the packages created by this action.
#
# The Chart version must be the same than the GITHUB_REF_NAME (release's tag), in other words the
# GitHub Release must match the Chart version for consistency.
#

shopt -s inherit_errexit
set -eu -o pipefail

# current script directory path
readonly source_dir="$(dirname ${BASH_SOURCE[0]})"

source "${source_dir}/common.sh"
source "${source_dir}/inputs.sh"

# path to the script to generate release notes
readonly generate_notes_sh="${source_dir}/notes.sh"

[[ ! -f "${generate_notes_sh}" ]] &&
	fail "Unable to find '${generate_notes_sh}'"

# Packages the local helm chart using `helm package`, using as destination directory the `dirname` of
# chart taball file, after packaging asserts the tarball exists
function package_helm_chart() {
	local _destination_dir="$(dirname ${CHART_TARBALL})"

	helm package --destination="${_destination_dir}" . >/dev/null

	[[ ! -f "${CHART_TARBALL}" ]] &&
		fail "'${CHART_TARBALL}' is not found!"

	return 0
}

# Renders the task file resource using `helm template`, asserts the rendered file is created.
function render_helm_chart_template() {
	helm template . >${RENDERED_TASK_FILE}

	[[ ! -f "${RENDERED_TASK_FILE}" ]] &&
		fail "Rendered task file is not found at '${RENDERED_TASK_FILE}'!"

	return 0
}

# Uses crane to set the repository reference as image's annotation, the GitHub container registry
# links the image with the respective project.
function set_image_annotations() {
	crane mutate --annotation="org.opencontainers.image.source=${GITHUB_REPOSITORY_URL}" ${1}
}

# creates the helm chart container image using `helm push`, which creates a image using the
# chart-name as the image name, and chart-version as tag. That's a Helm convention enforced to
# install the chart via container image.
function create_helm_chart_image() {
	local _registry_namespace="${1}"

	helm push ${CHART_TARBALL} "oci://${_registry_namespace}"
	set_image_annotations "${_registry_namespace}/${CHART_NAME}:${CHART_VERSION}"
}

# Creates the tekton task bundle container image, setting the regular annotations right after
function create_task_bundle_image() {
	local _image_tag="${1}"

	tkn bundle push ${_image_tag} --filenames="${RENDERED_TASK_FILE}"
	set_image_annotations ${_image_tag}
}

#
# Main
#

phase "Packaging Helm-Chart '${CHART_NAME}-${CHART_VERSION}' ('${BASE_DIR}')"
package_helm_chart

phase "Helm-Chart package contents '${CHART_TARBALL}'"
tar -ztvpf ${CHART_TARBALL}

phase "Rendering template on a single Task file '${RENDERED_TASK_FILE}'"
render_helm_chart_template
ls -lh ${RENDERED_TASK_FILE}

phase "Creating Helm-Chart image '${LOCAL_CHART_IMAGE_TAG}'"
create_helm_chart_image ${LOCAL_REGISTRY_NAMESPACE}

phase "Creating Tekton Task Bundle image '${LOCAL_BUNDLE_IMAGE_TAG}'"
create_task_bundle_image ${LOCAL_BUNDLE_IMAGE_TAG}

phase "Uploading Tekton Task and Helm-Chart package to release '${GITHUB_REF_NAME}'"
gh release upload --clobber ${GITHUB_REF_NAME} ${RENDERED_TASK_FILE} ${CHART_TARBALL}

# full path to the markdown file where the generated release-notes will be stored
readonly release_notes_md="${BASE_DIR}/release-notes.md"

phase "Generating release notes ('${release_notes_md}')"
${generate_notes_sh} ${release_notes_md}
set -x
cat ${release_notes_md}
set +x

phase "Editing GitHub Relase to include release notes"
gh release edit --draft --notes-file=${release_notes_md} --tag=${GITHUB_REF_NAME} ${GITHUB_REF_NAME}

phase "Logging in the Container-Registry '${TARGET_REGISTRY}' ('${GITHUB_ACTOR}')"
crane auth login --username="${GITHUB_ACTOR}" --password-stdin ${TARGET_REGISTRY} <<<${GITHUB_TOKEN}

phase "Pushing Tekton Task Bundle container image '${TARGET_BUNDLE_IMAGE_TAG}'"
crane copy ${LOCAL_BUNDLE_IMAGE_TAG} ${TARGET_BUNDLE_IMAGE_TAG}

phase "Pushing Helm-Chart container image '${TARGET_CHART_IMAGE_TAG}'"
crane copy ${LOCAL_CHART_IMAGE_TAG} ${TARGET_CHART_IMAGE_TAG}

# removing temporary directoy only when it has been created by this script, using the temporary
# directory patter informed to mktemp early on
if [[ "${BASE_DIR}" == "/tmp/release."* ]]; then
	phase "Cleaning up temporary directory ('${BASE_DIR}')"
	rm -rf ${BASE_DIR}
fi
