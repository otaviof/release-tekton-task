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

This action is meant to run when a new [repository release is created][githubReleaseDocs], the action expects to find a draft release in order to upload the artifacts and generate the release notes accordingly.

Make sure the action only runs when a `tag` is issued, as the example above shows, and a draft release is already created for the `tag`. After the action is executed you can publish the release.

## Inputs

| Input               | Required | Default   | Description                                       |
| :------------------ | :------: | :-------- | :------------------------------------------------ |
| `bundle_tag_suffix` | `false`  | `-bundle` | Tekton Task-Bundle OCI container-image tag suffix |
| `cli_version`       | `false`  | `latest`  | [Tekton CLI (`tkn`)][tektonCLI] version           |
| `helm_version`      | `false`  | `latest`  | [Helm CLI (`helm`)][helm] version                 |
| `crane_version`     | `false`  | `latest`  | [`go-containerregistry/crane`][crane] version     |

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

The [Tekton Task-Bundle][tektonTaskBundle] container-image receives the input `bundle_tag_suffix` to compose the final tag.

## Release Notes

Release note are generated automatically, with the respective commands to copy-and-paste to rollout the release artifacts.

[crane]: https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md
[githubReleaseDocs]: https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository#creating-a-release
[helm]: https://github.com/helm/helm
[tektonCLI]: https://github.com/tektoncd/cli
[tektonTaskBundle]: https://tekton.dev/docs/pipelines/tekton-bundle-contracts/
[testWorkflow]: https://github.com/otaviof/release-tekton-task/actions/workflows/test.yaml
[testWorkflowBadge]: https://github.com/otaviof/release-tekton-task/actions/workflows/test.yaml/badge.svg