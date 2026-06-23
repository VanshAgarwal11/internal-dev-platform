#!/usr/bin/env bash
# Create the k3d cluster from the committed config.
# This is step 1 of bootstrapping the platform.
set -euo pipefail

k3d cluster create --config clusters/devplatform.yaml

echo "Cluster created. Verify with: kubectl get nodes"
echo "Next: run scripts/install-cert-manager.sh, then scripts/install-argocd.sh"
