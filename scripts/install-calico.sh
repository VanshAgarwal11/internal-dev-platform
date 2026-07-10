#!/usr/bin/env bash
# Install Calico CNI via the Tigera operator. Idempotent — safe to re-run.
set -euo pipefail

CALICO_VERSION="v3.27.0"

# apply (not create) so re-runs don't error on existing resources
kubectl apply --server-side --force-conflicts -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"

echo "Waiting for tigera-operator to be ready..."
kubectl -n tigera-operator rollout status deployment/tigera-operator --timeout=300s

kubectl apply -f - <<'INNER'
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    containerIPForwarding: Enabled
    ipPools:
      - blockSize: 26
        cidr: 192.168.0.0/16
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
INNER

echo "Waiting for calico-node pods to be ready (generous timeout for slow cold pulls)..."
# wait for the pods to EXIST first, then for readiness — avoids the "no matching resources" race
sleep 15
kubectl -n calico-system wait --for=condition=ready pod --selector=k8s-app=calico-node --timeout=900s

echo "Calico installed and ready."
