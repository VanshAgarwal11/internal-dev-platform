# Engineering devlog

A running journal of what I built, what broke, and what I learned.
Newest entries at the top.


---
## Day 7 — Observability stack + reproducibility hardening

**Goal:** Add monitoring (Prometheus + Grafana) the GitOps way, then prove the
whole platform rebuilds from git on a clean cluster.

**Did:**
- Deployed kube-prometheus-stack via a single ArgoCD Application (Helm source,
  inline values), trimmed for 16GB (Alertmanager disabled, short retention,
  capped resources). One `git push` → root app auto-detected it → stack deployed.
- Set explicit resource requests/limits in the hello base Deployment (deterministic
  QoS, no longer LimitRange-dependent).
- Added scripts/bootstrap-all.sh to orchestrate the full bootstrap with
  condition-based waits.
- Hardened install scripts for idempotency and slow-connection cold pulls.

**Learned — the "no data" panel that found a real bug:**
- Grafana CPU/memory *utilization* panels showed "no data" for dev but worked for
  prod. Root cause: dev's hello pod was `besteffort` QoS (no resource requests), so
  utilization = usage ÷ requests had no denominator. prod's pods were `burstable`.
- Why dev lost its requests: on the Calico rebuild, ArgoCD created the hello pod
  BEFORE the LimitRange existed in that namespace — and LimitRange only injects into
  pods created after it. Ordering race between two separate ArgoCD Applications.
- Fix: set requests explicitly in the Deployment (deterministic, order-independent).
  LimitRange stays as a safety net for apps that forget. Belt and suspenders.
- QoS classes: besteffort (no requests) / burstable (some) / guaranteed (requests=limits).
- Meta-lesson: "no data" on a dashboard didn't mean monitoring was broken — monitoring
  correctly surfaced a real workload misconfiguration. Observability doing its job.

**Learned — the clean-rebuild test found ordering + idempotency bugs:**
- cert-manager install failed on rebuild because Calico wasn't Ready yet (no networking
  → startupapicheck couldn't reach the API). Bootstrap steps have ordering dependencies.
- Failed install left a partial Helm release; retry broke with "name already in use"
  because scripts used non-idempotent `helm install`. Fix: `helm upgrade --install --wait`.
- "Stuck" Calico (~17 min in ContainerCreating) was SLOW IMAGE PULLS on slow WiFi
  (calico/cni took 6 min, calico/node 5m43s to pull), NOT resource starvation — diagnosed
  via `kubectl get events`. Pods were besteffort and scheduled instantly.
- `kubectl wait --timeout=300s` was too short for a cold pull. Raised to 900s. Timeouts
  must budget worst-case cold-pull time, not warm-cluster time. Images now cached → next
  rebuild far faster.
- Meta-lesson: reasoned-correct ≠ proven-correct. The rebuild test caught bugs that
  "works on my running cluster" never would have.

**Next:**
- Finish the rebuild to fully prove reproducibility end-to-end.
- Commit the hardened idempotent scripts.
- Consider: is monitoring too heavy for the always-on core, or bring it up separately?

---

## Day 6 - Calico migration: NetworkPolicy finally enforced
**Calico migration — NetworkPolicy finally enforced (Day 6, the payoff):**
- Recreated the exact Day 2 test on the Calico cluster. Results:
  - prod→prod WITH policies: SUCCEEDS (nginx page) — allow rule now enforces correctly.
  - dev→prod WITH policies: TIMES OUT after 5003ms — deny enforces, Calico-style DROP.
  - dev→prod AFTER deleting policies: SUCCEEDS again — control test proving the policy
    caused the block, not unrelated networking.
- The timeout (DROP) vs the old instant 2ms reject (kube-router REJECT/RST) is the visible
  fingerprint confirming the CNI changed and now enforces per spec.
- Proven end to end: my YAML was always correct; kube-router's allow handling was broken;
  Calico fixes it. Closed a thread open since Day 2.
- Meta-lesson: across this investigation I tested 3 allow formulations, adjudicated 2
  conflicting AI opinions, and let controlled experiments decide every time. The experiment
  is the authority, not the assistant.

**Adjudicating Calico vs a cheap fix (engineering judgment):**
- A second opinion argued the Calico migration was overkill and proposed a lighter fix:
  use namespaceSelector with the built-in kubernetes.io/metadata.name label instead of
  an empty podSelector. Strong argument — don't rip out a CNI for a YAML quirk.
- But I'd already tested a namespaceSelector on Day 2 and it failed. Tested this new
  variant too (built-in label) — also failed, same instant REJECT.
- Proven: kube-router fails to process ingress ALLOW rules regardless of formulation
  (tested empty podSelector, custom namespaceSelector, built-in namespaceSelector — all 3 fail).
  Not a syntax quirk; a broken allow implementation. Migration is justified.
- Also learned the real cause of the 1ms error: kube-router uses iptables REJECT (sends TCP
  RST) rather than DROP, hence instant "connection refused" instead of a timeout.
- Lesson: tested the cheap fix before the expensive one, and adjudicated two conflicting AI
  recommendations against my own experimental data rather than trusting either. The experiment decided.


**Learned:**
- Made platform/environments/ GitOps-managed via ArgoCD. No sync-waves needed — ArgoCD's
  retry-within-sync self-corrected the namespace-then-quota ordering on a clean-cluster rebuild.

**Next:**
- My environment setup was bucket-two YAML but not yet GitOps-managed — you applied it by hand. A future improvement would be to bring platform/environments/ under an ArgoCD Application too, so even namespaces are GitOps-managed. 

---
## Day 5 - ArgoCD and the app-of-apps pattern

**Did:**
 - Added ArgoCD
 - Restructured ArgoCD into app-of-apps: root Application managing hello-dev/staging/prod


**Watched ArgoCD self-heal (the GitOps payoff):**
- Manually scaled hello to 3 replicas with `kubectl scale`. ArgoCD detected the drift
  (live=3 vs git=1), flipped OutOfSync, and reverted to 1 within a second — selfHeal in action.
- Mechanism: ArgoCD continuously compares live state to git; selfHeal:true makes it
  *correct* drift automatically, not just report it.
- Mindset shift: under GitOps you can't fix things with manual kubectl — changes not in
  git get reverted. The only way to change the cluster is to change git. Push-based habits
  (kubectl edit) are an anti-pattern here.

  **Next:**
  - Start with ADR-0003

---
## Day 4 - Kustomize and NetworkPolicy

**NetworkPolicy diagnosis, sharpened (Day 4):**
- Cross-checked the unresolved policy issue on the internet. Found that
  k3s bundles kube-router to enforce NetworkPolicies. kube-router is why
  my policies enforced at all.
- My own dev experiment found out: same image, same setup, traffic toggled
  purely by applying/removing the policy. The policy is the cause.
- Sharpest diagnosis: Propably kube-router enforces the DENY correctly but mishandles the
  selector-based ALLOW rule. Open question for the Calico migration: does Calico
  handle the allow where kube-router doesn't?

**Did:**
- Learned to use/write Kustomize and overlays better by adding ingress to the hello app with per-environment hsotnames

**Learned:** 
- IngressClassName(in ingress.yaml) must name the real controller (ex: traefik), not an arbitrary string
- An Ingress with no host matches all traffic
- JSON-pointer patch paths like /spec/rules/0/host index into lists.

**Next:**
- GitOps with ArgoCD — make git the source of truth so pushing deploys automatically.

---
## Day 3 — First app deployed across all environments with Kustomize

**Goal:** Deploy a real app (hello) into dev, staging, and prod from a single
source of truth, and learn the pattern that avoids per-environment config drift.

**Did:**
- Wrote my first Deployment and Service YAML myself (from official boilerplate, then edited)
- Deployed hello to dev; confirmed the Service routed traffic (got the nginx page back)
- Restructured into a Kustomize base + dev/staging/prod overlays
- Deployed to all three environments; prod runs 2 replicas via an overlay patch
- Switched to small, per-logical-unit commits

**Learned:** 
- Deployment → ReplicaSet → Pod chain: The apps run inside pods and all the pods are created inside a replicaset to manage scaling and HA in a deployment.
- LimitRange auto-injection: The limit ranges applied on a namespace automaticlly applies if a deployment yaml file doesnt explicitly state the limits
- Why the Kustomize base must be environment-agnostic: So that each enviroment overlay file can use it as a base to build upon and add environment specific configurations.
- `kubectl kustomize` vs `apply -k`: `kubectl kustomize <overlay>` builds and prints the merged YAML to the terminal without touching the cluster (a preview); `kubectl apply -k <overlay>` builds the same YAML and applies it to the cluster. Preview-then-apply is the safe habit.
- Small commits — why they help: For easy granular control and might help later to precisely find the right place to look at when something breaks.

**Next:**
- Setup ingress on the hello app to make the pod accessible via browser.


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