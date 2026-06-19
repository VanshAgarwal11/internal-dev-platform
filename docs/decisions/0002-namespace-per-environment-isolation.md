# ADR 0002: One namespace per environment with quotas and limits

**Status:** Accepted
**Date:** 2026-06-19

## Context
The platform needs isolated dev, staging, and prod environments on a single
local k3d cluster, with guardrails preventing one environment from exhausting
shared resources, sized to a 16 GB MacBook running Docker, VS Code, and a
browser concurrently.

## Decision
Use one Kubernetes namespace per environment, each with a ResourceQuota and a
LimitRange. Size quotas against the cluster's real shared-host capacity rather
than the per-node allocatable figures, which over-report because k3d nodes are
containers sharing one host.

## Consequences
- Strong logical isolation without the cost of separate clusters.
- Quotas were deliberately lowered from an initial draft to fit real capacity —
  capacity planning against the target environment, not a workaround.
- Network-level isolation was attempted via NetworkPolicy but is deferred to
  Calico (see ADR 0003) due to partial enforcement in the default CNI.
