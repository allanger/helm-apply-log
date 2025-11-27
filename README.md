# Helm apply log

This plugin can be used as a post renderer to append a `ConfigMap` with some information about the release.
It contains the following data:

- Author
- SHA
- Branch
- CI (When CI env variable is set)
- Status (It's "dirty" when there are uncommitted changes, otherwise - "clean")

## Installation

Execute the following command:
```shell
# -- For the version v0.1.0
$ export VERSION=v0.1.0
$ helm plugin install "https://github.com/ONPIER-OSS/helm-apply-log/archive/refs/tags/${VERSION}.tar.gz"
```
