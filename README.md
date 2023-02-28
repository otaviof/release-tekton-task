Tekton Task Release Action
--------------------------

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
      contents: write
      packages: write
    steps:
      - uses: otaviof/release-tekton-task@main
        with:
          repository_name: ${{ github.event.repository.name }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input             | Required | Description                                         |
|:------------------|:--------:|:----------------------------------------------------|
| `repository_name` | `true`   | GitHub repository name                              |
| `bundle_suffix`   | `false`  | Tekton Task Bundle image name suffix (`tkn bundle`) |
| `cr_version`      | `false`  | Helm Chart-Releaser (`cr`) version                  |
| `cli_version`     | `false`  | Tekton CLI (`tkn`) version                          |
| `helm_version`    | `false`  | Helm CLI (`helm`) version                           |

## Tools

The following tools are installed for the release process:

- `cr` ([`helm/chart-releaser`][helmCR]): packages and upload the Helm-Chart to GitHub Release
- `helm` ([`helm/helm`][helm]): builds the Helm-Chart container-image (OCI)
- `tkn` ([`tekton/cli`][tektonCLI]): builds Tekton Task Bundle container-image (OCI)

# Release Contents

The action expects to find a `Chart.yaml` file in the root of the repository, from this file it extracts the Chart name and version. The version must match the current Git tag, the release subject, the reference name is informed via `GITHUB_REF_NAME`, environment variable set by default.

The release artifacts are described below, the GitHub organization is `actor` and the repository name is `example` with a Chart version `0.0.1`, please consider:

## Helm-Chart Package

Using `helm package` command this action packages the `.tgz` tarball with the Helm-Chart data, following the common Helm standard.

```
example-0.0.1.tgz
```

## Helm-Chart OCI Container-Image

Using `helm push` the `.tgz` package becomes a OCI container image. For instance:

```
oci://ghcr.io/actor/example:0.0.1
```

## Tekton Task (YAML)

The Tekton Task resource is rendered as a regular `.yaml` file using `helm template`. For instance:

```
example-0.0.1.yaml
```

## Tekton Task Bundle Container-Image

Using `tkn bundle` another OCI container image is created for the Tekton Task Bundle. The image name is based on the input `bundle_suffix`, as the following example:

```
oci://ghcr.io/actor/example-bundle:0.0.1
```

[helmCR]: https://github.com/helm/chart-releaser
[helm]: https://github.com/helm/helm
[tektonCLI]: https://github.com/tektoncd/cli