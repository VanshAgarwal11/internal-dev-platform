#!/usr/bin/env bash
# Full platform bootstrap: cluster -> Calico -> cert-manager -> ArgoCD -> root app.
# Idempotent and safe to re-run — each step skips or no-ops work already done.
set -euo pipefail

echo "==> Step 1/5: Creating cluster (skips if exists)..."
./scripts/create-cluster.sh

echo "==> Step 2/5: Installing Calico..."
./scripts/install-calico.sh

echo "==> Waiting for all nodes to become Ready (Calico must be up)..."
kubectl wait --for=condition=Ready nodes --all --timeout=900s

echo "==> Step 3/5: Installing cert-manager..."
./scripts/install-cert-manager.sh

echo "==> Step 4/5: Installing ArgoCD..."
./scripts/install-argocd.sh

echo "==> Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=900s \
  deployment/argocd-server -n argocd

echo "==> Step 5/5: Applying the root Application (GitOps takes over)..."
kubectl apply -f platform/argocd/root-app.yaml

echo ""
echo "Bootstrap complete. ArgoCD will now reconcile the rest from git."
echo "Watch progress:  kubectl get applications -n argocd"
echo "ArgoCD password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo"
