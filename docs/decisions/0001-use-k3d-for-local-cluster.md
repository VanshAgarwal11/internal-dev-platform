# ADR 0001: Use k3d for the local Kubernetes cluster

**Status:** Accepted
**Date:** (today's date)

## Context
This project needs a local Kubernetes cluster that runs on an Apple Silicon
MacBook (M1 Pro, 16 GB RAM) at zero cost, with no public cloud. It must support
multiple namespaced environments and, later, a local image registry for CI.

## Options considered
- **Minikube:** Mature, feature-rich, but runs a single-node VM on macOS.
- **kind:** Pure upstream Kubernetes in Docker; registry needs manual setup.
- **k3d:** Wraps lightweight k3s in Docker; fast startup, built-in registry.

## Decision
Use k3d. It starts in seconds on Docker (already installed), gives a built-in
local registry needed in the CI phase, and matches the resource constraints of
a 16 GB laptop.

## Consequences
- k3s omits a few upstream components; acceptable for this project's scope.
- Cluster config is captured in a YAML file under clusters/ for reproducibility.
