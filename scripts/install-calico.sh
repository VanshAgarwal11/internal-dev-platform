#!/usr/bin/env bash
# Install Calico CNI via the Tigera operator.
# Run immediately after creating the cluster with clusters/devplatform-calico.yaml,
# while nodes are still NotReady (no CNI yet).
set -euo pipefail

CALICO_VERSION="v3.27.0"

kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"

echo "Waiting for tigera-operator to be ready..."
kubectl -n tigera-operator rollout status deployment/tigera-operator --timeout=120s

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

echo "Waiting for Calico nodes to be ready..."
kubectl -n calico-system wait --for=condition=ready pod --selector=k8s-app=calico-node --timeout=180s || true
echo "Calico installed. Check: kubectl get pods -n calico-system"
