#!/bin/bash

helm package helm/vault-agent-auto-inject-webhook/
version=$(cat helm/vault-agent-auto-inject-webhook/Chart.yaml | yaml2json | jq -r '.version')
mv vault-agent-auto-inject-webhook-$version.tgz docs/
helm repo index docs --url https://patoarvizu.github.io/vault-agent-auto-inject-webhook
helm-docs
mv helm/vault-agent-auto-inject-webhook/README.md docs/index.md
git add docs/