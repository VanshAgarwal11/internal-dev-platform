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
- Wrote default-deny + same-namespace NetworkPolicies for prod
- Inspected the bundled Traefik ingress (didn't install a second controller)
- Installed cert-manager via Helm and created a self-signed ClusterIssuer

**Learned:**
- Capacity planning: quotas must fit the cluster's *real* shared-host capacity, not total RAM. I lowered my initial quota draft to match — this is right-sizing to the target environment, the same discipline as sizing against a cloud budget or node pool.
- The allocatable illusion: each k3d node reports 10 CPU and full RAM because the nodes are containers sharing one Mac, so the scheduler over-counts. `kubectl top nodes` shows the honest usage; allocatable does not.
- metrics-server returns no data for ~1 min after cluster start — it needs the pod scheduled plus one full scrape interval before it can serve metrics. My earlier guess ("waits for the server node") was close but the real cause is the scrape cycle.
- NetworkPolicy is only *intent* unless the CNI enforces it. k3d's default Flannel does not implement NetworkPolicy, so a default-deny rule doesn't actually block traffic — I verified this with a pod-to-pod test. Calico would enforce it.
- "Inspect before installing" — k3d already bundles Traefik, so installing nginx would have caused two controllers to fight over the same ports.
- CRDs (Custom Resource Definitions) are how cert-manager teaches Kubernetes new object types like `Certificate` and `ClusterIssuer`; they must be installed for those kinds to exist.

**Challenges:**
- (fill in anything that actually tripped you up as you go)

**Next:**
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