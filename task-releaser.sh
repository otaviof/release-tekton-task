#!/usr/bin/env bash
#
# Uses the `helm/chart-releaser` (cr) to package and relase the local chart, the artifact version
# must be the same than the current repository tag. The script renders the Task resource in a single
# file to become part of the release artifacts.
#
# This script packages and upload the data to GitHub using `cr` and `gh` (installed by default on
# GitHub Actions runtime).
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
readonly GITHUB_REPOSITORY_NAME="${GITHUB_REPOSITORY_NAME:-}"

[[ -z "${GITHUB_REF_NAME}" ]] && \
	fail "GITHUB_REF_NAME environment variable is not set"

[[ -z "${GITHUB_ACTOR}" ]] && \
	fail "GITHUB_ACTOR environment variable is not set"

[[ -z "${GITHUB_TOKEN}" ]] && \
	fail "GITHUB_TOKEN environment variable is not set"

[[ -z "${GITHUB_REPOSITORY_NAME}" ]] && \
	fail "GITHUB_REPOSITORY_NAME environment variable is not set"

# making sure the chart name and version can be extracted from the Chart.yaml file, it must be
# located in the current directory where the script is being executed
phase "Extrating chart name and version"

[[ ! -f "Chart.yaml" ]] && \
	fail "Chart.yaml is not found on '${PWD}'"

# estracting name and version from the Chart.yaml file directly
readonly CHART_NAME="$(awk '/^name:/ { print $2 }' Chart.yaml)"
readonly CHART_VERSION="$(awk '/^version:/ { print $2 }' Chart.yaml)"

[[ -z "${CHART_NAME}" ]] && \
	fail "CHART_NAME can't be otainted from Chart.yaml"

[[ -z "${CHART_VERSION}" ]] && \
	fail "CHART_VERSION can't be otainted from Chart.yaml"

[[ "${GITHUB_REF_NAME}" != "${CHART_VERSION}" ]] && \
	fail "Git tag '${GITHUB_REF_NAME}' and chart version '${CHART_VERSION}' must be the same!"

#
# Packaging Chart and Rendering Task
#

# pre-defined location for the tarball to be packaged on the next step
readonly CR_RELEASE_PKGS=".cr-release-packages"
readonly CHART_TARBALL="${CR_RELEASE_PKGS}/${CHART_NAME}-${CHART_VERSION}.tgz"

# creating a tarball out of the chart, ignoring files based on the `.helmignore`
phase "Packaging chart '${CHART_NAME}-${CHART_VERSION}'"
cr package

[[ ! -f "${CHART_TARBALL}" ]] && \
	fail "'${CHART_TARBALL}' is not found!"

# showing the contents of the tarball, here it's important to check if there are cluttering that
# should be added to the `.helmignore`
phase "Package contents '${CHART_TARBALL}'"
tar -ztvpf ${CHART_TARBALL}

# creating a single file YAML payload with the task, it will be uploaded to the release page, side by
# side with the chart tarball
readonly TASK_PAYLOAD_FILE="${CR_RELEASE_PKGS}/${CHART_NAME}-${CHART_VERSION}.yaml"
phase "Rendering template on a single Task file ('${TASK_PAYLOAD_FILE}')"
helm template ${CHART_NAME} . >${TASK_PAYLOAD_FILE}

[[ ! -f ${TASK_PAYLOAD_FILE} ]] && \
	fail "Rendered task file is not found at '${TASK_PAYLOAD_FILE}'!"

#
# Release Upload
#

readonly ACTOR_REPOSITORY="${GITHUB_ACTOR}/${GITHUB_REPOSITORY_NAME}"

# uploading the chart release using it's version as the release name
phase "Uploading chart '${CHART_TARBALL}' to '${ACTOR_REPOSITORY}' ($CHART_VERSION)"
cr upload \
	--owner="${GITHUB_ACTOR}" \
	--git-repo="${GITHUB_REPOSITORY_NAME}" \
	--token="${GITHUB_TOKEN}" \
	--release-name-template='{{ .Version }}'

# uploading the task file to the same release
phase "Uploading task '${TASK_PAYLOAD_FILE}' to '${ACTOR_REPOSITORY}' ($CHART_VERSION)"
gh release upload --clobber "${GITHUB_REF_NAME}" ${TASK_PAYLOAD_FILE}
