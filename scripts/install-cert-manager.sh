#!/usr/bin/env bash
# Bootstrap cert-manager and the self-signed ClusterIssuer.
# Run once after the k3d cluster is created.
set -euo pipefail

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

echo "Waiting for cert-manager webhook to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/cert-manager-webhook -n cert-manager

kubectl apply -f platform/cert-manager/selfsigned-issuer.yaml

echo "cert-manager installed and self-signed ClusterIssuer applied."
