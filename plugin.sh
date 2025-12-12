#!/usr/bin/env bash

cat <&0
echo "---"
# -- If executed from the git repository, detect the remote
if [[ $(git rev-parse --is-inside-work-tree) == 'true' ]]; then
  GIT_REMOTE_NAME="$(git remote)"
  GIT_REMOTE_URL="$(git remote get-url ${GIT_REMOTE_NAME})"
else
  GIT_REMOTE_URL="Not inside a git repo"
fi

HELM_VERSION="$(helm version --short)"

HELMFILE_VERSION="Helmfile not detected"

if ! [ -z "$(command -v helmfile)" ]; then
  HELMFILE_VERSION="$(helmfile version -o=short)"
fi

HELM_USER="${HELM_USER:-$USER}"
RELEASE_NAME="${1}"

if [ -z "${CI}" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  SHA=$(git rev-parse --short HEAD)
  STATUS=$(test -z `git status --porcelain` && echo clean || echo dirty)
  kubectl create configmap --dry-run=client \
    "${RELEASE_NAME}-apply-log" -o yaml \
      --from-literal author="${HELM_USER}" \
      --from-literal branch="${BRANCH}" \
      --from-literal git_sha="${SHA}" \
      --from-literal git_status="${STATUS}" \
      --from-literal git_remote_url="${GIT_REMOTE_URL}" \
      --from-literal helm_version="${HELM_VERSION}" \
      --from-literal helmfile_version="${HELMFILE_VERSION}" \
    | yq 'del(.metadata.creationTimestamp)'
else
  # -- Detect a CI url
  CI_URL="CI URL not found"
  if ! [ -z "${GITHUB_RUN_ID}" ]; then
    CI_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  elif ! [ -z "${CI_PIPELINE_URL}" ]; then
    CI_URL="${CI_PIPELINE_URL}"
  fi
  kubectl create configmap --dry-run=client \
    "${RELEASE_NAME}-apply-log" -o yaml \
      --from-literal author="${HELM_USER}" \
      --from-literal ci="true" \
      --from-literal git_remote_url="${GIT_REMOTE_URL}" \
      --from-literal git_ci_url="${CI_URL}" \
      --from-literal helm_version="${HELM_VERSION}" \
      --from-literal helmfile_version="${HELMFILE_VERSION}" \
    | yq 'del(.metadata.creationTimestamp)'
fi
