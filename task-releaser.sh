#!/usr/bin/env bash
#
# Release script to pacakge and upload a Helm-Chart packaging a Tekton Task. The following items are
# part of the release:
#
#  - Helm-Chart tarball (`cr`)
#  - Helm-Chart OCI container-image (`helm push`)
#  - Tekton-Task YAML (`helm template`)
#  - Tekton Bundle OCI container-image (`tkn bundle`)
#
# The Chart version must be the same than the GITHUB_REF_NAME, in other words the release tag must
# match the Chart version for consistency.
#

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"

# inspecting the enviroment variables to load all the configuration the chart-releaser needs, that
# includes the GitHub repository coordinates and access token
phase "Loading configuration from environment variables"

# branch or tag triggering the workflow, for the release purposes it must be the same than the chart
# version, thus a repository tag
readonly GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"

# github username (actor) and token
readonly GITHUB_ACTOR="${GITHUB_ACTOR:-}"
readonly GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# the repository name without the user/organization
readonly INPUT_REPOSITORY_NAME="${INPUT_REPOSITORY_NAME:-}"
# tekton bundle image suffix
readonly INPUT_BUNDLE_SUFFIX="${INPUT_BUNDLE_SUFFIX:-}"

for v in GITHUB_REF_NAME GITHUB_ACTOR GITHUB_TOKEN INPUT_REPOSITORY_NAME INPUT_BUNDLE_SUFFIX; do
	[[ -z "${!v}" ]] &&
		fail "'${v}' environment variable is not set!"
done

# making sure the chart name and version can be extracted from the Chart.yaml file, it must be
# located in the current directory where the script is being executed
phase "Extrating chart name and version from './Chart.yaml'"

[[ ! -f "Chart.yaml" ]] &&
	fail "Chart.yaml is not found on '${PWD}'"

# estracting name and version from the Chart.yaml file directly
readonly chart_name="$(awk '/^name:/ { print $2 }' Chart.yaml)"
readonly chart_version="$(awk '/^version:/ { print $2 }' Chart.yaml)"

[[ -z "${chart_name}" ]] &&
	fail "'chart_name' can't be otainted from Chart.yaml"

[[ -z "${chart_version}" ]] &&
	fail "'chart_version' can't be otainted from Chart.yaml"

[[ "${GITHUB_REF_NAME}" != "${chart_version}" ]] &&
	fail "Git tag '${GITHUB_REF_NAME}' and chart version '${chart_version}' must be the same!"

#
# Registry Login
#

readonly container_registry="ghcr.io"

phase "Logging in the Container-Registry '${container_registry}' ('${GITHUB_ACTOR}')"
helm registry login --username="${GITHUB_ACTOR}" --password="${GITHUB_TOKEN}" ${container_registry}

#
# Packaging Chart and Rendering Task
#

# pre-defined location for the tarball to be packaged on the next step
readonly cr_release_pkgs=".cr-release-packages"
readonly chart_tarball="${cr_release_pkgs}/${chart_name}-${chart_version}.tgz"

# creating a tarball out of the chart, ignoring files based on the `.helmignore`
phase "Packaging chart '${chart_name}-${chart_version}'"
cr package

[[ ! -f "${chart_tarball}" ]] &&
	fail "'${chart_tarball}' is not found!"

# showing the contents of the tarball, here it's important to check if there are cluttering that
# should be added to the `.helmignore`
phase "Package contents '${chart_tarball}'"
tar -ztvpf ${chart_tarball}

# creating a single file YAML payload with the task, it will be uploaded to the release page, side by
# side with the chart tarball
readonly task_payload_file="${cr_release_pkgs}/${chart_name}-${chart_version}.yaml"

phase "Rendering template on a single Task file ('${task_payload_file}')"
helm template ${chart_name} . >${task_payload_file}

[[ ! -f "${task_payload_file}" ]] &&
	fail "Rendered task file is not found at '${task_payload_file}'!"

#
# Release Upload
#

# composing the username (actor) and the repository
readonly actor_repository="${GITHUB_ACTOR}/${INPUT_REPOSITORY_NAME}"
# helm oci image uses the chart name and version to compose the image name and tag respectively
readonly oci_image="${container_registry}/${GITHUB_ACTOR}"

phase "Pushing Helm-Chart OCI image '${oci_image}'"
helm push ${chart_tarball} "oci://${oci_image}"

# tekton task bundle image needs to get the chart name plus suffix (to not collide with helm image),
# and the chart version as image tag
readonly oci_bundle_image="${oci_image}/${chart_name}:${chart_version}${INPUT_BUNDLE_SUFFIX}"

phase "Pushing Tekton Task Bundle image ('${oci_bundle_image}')"
tkn bundle push "${oci_bundle_image}" \
	--filenames="${task_payload_file}" \
	--remote-username="${GITHUB_ACTOR}" \
	--remote-password="${GITHUB_TOKEN}"

phase "Uploading chart '${chart_tarball}' to '${actor_repository}' (${chart_version})"
cr upload \
	--owner="${GITHUB_ACTOR}" \
	--git-repo="${INPUT_REPOSITORY_NAME}" \
	--token="${GITHUB_TOKEN}" \
	--release-name-template='{{ .Version }}'

phase "Uploading task '${task_payload_file}' to '${actor_repository}' (${chart_version})"
gh release upload --clobber "${GITHUB_REF_NAME}" ${task_payload_file}
