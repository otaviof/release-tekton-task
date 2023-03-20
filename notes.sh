#!/usr/bin/env bash
#
# Generates the release notes with installation instructions to the artifacts created.
#

shopt -s inherit_errexit
set -eu -o pipefail

# current script directory path
readonly source_dir="$(dirname ${BASH_SOURCE[0]})"

source "${source_dir}/common.sh"
source "${source_dir}/inputs.sh"

# path to the release notes to be generated
readonly output_file="${1}"

[[ -z "${output_file}" ]] &&
	fail "Output file must be informed as first argument!"

# release url directly to the chart version, the same as the relase tag
readonly release_url="${GITHUB_REPOSITORY_URL}/releases/download/${CHART_VERSION}"

exec cat <<EOS >${output_file}
# Using the Task

## Task Resource File

You can retrieve the task directly with \`kubectl\`, i.e:

\`\`\`bash
kubectl apply -f "${release_url}/${TASK_FILE_NAME}"
\`\`\`

## Tekton Task-Bundle

With \`tkn bundle\` you can rollout the Task from container-image, i.e:

\`\`\`bash
tkn bundle list "${TARGET_REGISTRY_NAMESPACE}/${CHART_NAME}:${BUNDLE_TAG}" task -o yaml | kubectl apply -f -
\`\`\`

## Helm-Chart

The Task is packaged as a Helm-Chart, you can choose between the traditional "tarball" (\`.tgz\` file) or the OCI container image, as shown below.

Installing the chart "tarball":

\`\`\`bash
helm install ${CHART_NAME} "${release_url}/${TARBALL_FILE_NAME}"
\`\`\`

Alternatively, you can use the Chart container image:

\`\`\`bash
helm install ${CHART_NAME} "oci://${TARGET_REGISTRY_NAMESPACE}/${CHART_NAME}" --version="${CHART_VERSION}"
\`\`\`
EOS
