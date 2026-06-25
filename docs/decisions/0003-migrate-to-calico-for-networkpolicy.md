# ADR 0003: Migrate from Flannel to Calico for NetworkPolicy enforcement

**Status:** Accepted
**Date:** 25th June 2026

## Context
The cluster ships with k3s's default Flannel CNI. Through controlled testing
(applying deny + allow policies in an isolated namespace and toggling them), I
confirmed that this cluster enforces the *deny* portion of NetworkPolicy but does
NOT correctly process the *allow* (ingress `from`) rules — neither an empty
podSelector nor an explicit namespaceSelector restored traffic. The result is
that a default-deny policy cannot be paired with a working allow rule, making
NetworkPolicy unusable for real segmentation here.

## Decision
Plan a migration to Calico, the reference implementation of the Kubernetes
NetworkPolicy spec, which fully supports selector-based allow rules, namespace
selectors, and egress policy. This will be done by recreating the k3d cluster
with Flannel's network policy controller disabled and Calico installed.

## Consequences
- NetworkPolicy intent (already committed in platform/environments/network-policies.yaml)
  becomes actually enforceable.
- Migration requires recreating the cluster (--flannel-backend=none and
  --disable-network-policy), which is itself a useful, documented exercise.
- Slightly higher resource footprint than Flannel; acceptable on 16 GB given
  current low usage.
- Until migrated, NetworkPolicies are removed from active namespaces to avoid a
  broken default-deny blocking legitimate traffic.
