#!/usr/bin/env bash
# Create the k3d cluster from the committed config. Idempotent — skips if the cluster exists.
set -euo pipefail

CLUSTER_NAME="devplatform"

if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
  echo "Cluster '${CLUSTER_NAME}' already exists — skipping creation."
else
  echo "Creating cluster '${CLUSTER_NAME}'..."
  k3d cluster create --config clusters/devplatform-calico.yaml
fi

echo "Cluster ready. Verify with: kubectl get nodes"
