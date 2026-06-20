# Engineering devlog

A running journal of what I built, what broke, and what I learned.
Newest entries at the top.

---

## Day 2 — Namespaced environments, quotas, network policies, certs

**Goal:** Turn the bare cluster into a structured multi-tenant platform —
isolated environments with resource guardrails, a network-security baseline,
and automated certificate management.

**Did:**
- Created dev / staging / prod namespaces declaratively (one YAML, applied with `kubectl apply -f`)
- Added ResourceQuotas and LimitRanges per namespace, right-sized to real capacity
- Wrote default-deny + same-namespace NetworkPolicies (kept as committed intent; see investigation below)
- Ran an extended controlled experiment on NetworkPolicy enforcement
- Inspected the bundled Traefik ingress (didn't install a second controller)
- Installed cert-manager via Helm and created a self-signed ClusterIssuer

**Learned:**
- Capacity planning: quotas must fit the cluster's *real* shared-host capacity, not total RAM. I lowered my initial quota draft to match — this is right-sizing to the target environment, the same discipline as sizing against a cloud budget or node pool.
- The allocatable illusion: each k3d node reports 10 CPU and full RAM because the nodes are containers sharing one Mac, so the scheduler over-counts. `kubectl top nodes` shows the honest usage; allocatable does not.
- metrics-server returns no data for ~1 min after cluster start — it needs the pod scheduled plus one full scrape interval before it can serve metrics. My earlier guess ("waits for the server node") was close but the real cause is the scrape cycle.
- "Inspect before installing" — k3d already bundles Traefik, so installing nginx would have caused two controllers to fight over the same ports.
- CRDs (Custom Resource Definitions) are how cert-manager teaches Kubernetes new object types like `Certificate` and `ClusterIssuer`; they must be installed for those kinds to exist.

**The NetworkPolicy investigation (the big one):**
- Set out expecting NetworkPolicies would NOT be enforced (the common claim is that Flannel doesn't implement them). The opposite turned out to be true.
- Ran a controlled experiment in dev: target+client worked reliably with no policy (3x in a row), failed the instant both policies were applied, and worked again once policies were removed. One variable, repeatable in both directions — this proved the cluster DOES enforce NetworkPolicy.
- But the allow rule never restored traffic. Tested empty `podSelector: {}` and an explicit `namespaceSelector` (matchLabels environment=dev) — both failed. Only the deny half ever worked.
- Conclusion: this CNI enforces deny but not the selector-based allow rules — partial NetworkPolicy support. The fix is Calico, the reference implementation. Logged as ADR 0003 (status: Proposed).
- Removed the policies from active namespaces afterward so a broken default-deny wouldn't silently block legitimate traffic in later phases; kept `network-policies.yaml` in the repo as intent to be activated post-Calico.

**Debugging skills practiced:**
- Distinguishing a *timeout* (policy drop) from an *instant connection refused* (no path / no listener).
- Using `kubectl get endpoints` to verify service-to-pod wiring.
- Confirming a suspected cause by removing it and re-testing, not by reasoning alone.
- Isolating one variable across namespaces to run a true controlled experiment.
- Reading `kubectl describe networkpolicy` to see what a policy actually allows.

**Key lesson:**
- Verify a CNI's actual capabilities empirically before trusting documentation or assumptions about it. The observed behavior contradicted the standard "Flannel doesn't enforce" claim — the only way to know was to test it directly and repeatedly.

**Challenges:**
- spent a long time chasing wrong theories before running the clean dev experiment; learned to isolate the variable sooner.

**Next:**
- Migrate to Calico (ADR 0003) so the committed NetworkPolicies become enforceable.
- Deploy the first sample app into all three environments and reach it over HTTPS through Traefik.

---

## Day 1 — Foundation and cluster bootstrap

**Goal:** Set up the toolchain, scaffold the repo, and bring up a local k3d cluster.

**Did:**
- Installed the toolchain (Docker, k3d, helm, kubectl)
- Scaffolded the repository structure
- Initialized git and made the first commit
- Created the k3d cluster (1 server, 2 agents)
- Pushed to GitHub

**Learned:**
- k3d runs k3s inside Docker containers, so "nodes" are really containers on the host

**Next:**
- Phase 2: namespaced environments, quotas, cert-manager