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

RELEASE_NAME="${1}"

if [ -z "${CI}" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  SHA=$(git rev-parse --short HEAD)
  STATUS=$(test -z `git status --porcelain` && echo clean || echo dirty)
  kubectl create configmap --dry-run=client \
    "${RELEASE_NAME}-apply-log" -o yaml \
      --from-literal author="${USER}" \
      --from-literal branch="${BRANCH}" \
      --from-literal sha="${SHA}" \
      --from-literal status="${STATUS}" \
      --from-literal remote_url="${GIT_REMOTE_URL}" \
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
      --from-literal author="${USER}" \
      --from-literal ci="true" \
      --from-literal remote_url="${GIT_REMOTE_URL}" \
      --from-literal ci_url="${CI_URL}" \
    | yq 'del(.metadata.creationTimestamp)'
fi
