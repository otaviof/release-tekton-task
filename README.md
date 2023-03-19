[![test][testWorkflowBadge]][testWorkflow]

`release-tekton-task`
---------------------

GitHub Action to release a Tekton Task.

# Usage

The following snippet shows the usage example, please note the attributes `permissions.contents` and `permissions.packages` required to allow the action upload the release data.


```yaml
on:
  push:
    tags:
      - "*"

jobs:
  release:
    permissions:
      # allows the action to create a new release
      contents: write
      # allows the action to upload relese artifacts
      packages: write
    steps:
      - uses: otaviof/release-tekton-task@main
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input               | Required | Description                                       |
| :------------------ | :------: | :------------------------------------------------ |
| `bundle_tag_suffix` | `false`  | Tekton Task-Bundle OCI container-image tag suffix |
| `cli_version`       | `false`  | [Tekton CLI (`tkn`)][tektonCLI] version           |
| `helm_version`      | `false`  | [Helm CLI (`helm`)][helm] version                 |
| `crane_version`     | `false`  | [`go-containerregistry/crane`][crane] version     |

# Release Contents

The action expects to find a `Chart.yaml` file in the root of the repository, from this file it extracts the Chart name and version. The version must match the current Git tag, informed via `GITHUB_REF_NAME` environment variable, set during action execution by default.

## Artifacts

The release artifacts are described below, the GitHub organization is `actor` and the repository is `example` containing a Chart version `0.0.1`, please consider:

| Artifact Name                              | Description                            |
| :----------------------------------------- | :------------------------------------- |
| `example-0.0.1.yaml`                       | Tekton Task resource                   |
| `oci://ghcr.io/actor/example:0.0.1-bundle` | Tekton Task-Bundle OCI container-image |
| `example-0.0.1.tgz`                        | Helm-Chart tarball                     |
| `oci://ghcr.io/actor/example:0.0.1`        | Helm-Chart OCI container-image         |

The Tekton Task-Bundle container-image receives the input `bundle_tag_suffix` to compose the final tag.

[crane]: https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md
[helm]: https://github.com/helm/helm
[tektonCLI]: https://github.com/tektoncd/cli
[testWorkflow]: https://github.com/otaviof/release-tekton-task/actions/workflows/test.yaml
[testWorkflowBadge]: https://github.com/otaviof/release-tekton-task/actions/workflows/test.yaml/badge.svg