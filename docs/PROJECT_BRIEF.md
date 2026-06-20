# Project brief — Internal Developer Platform (IDP)

> **Purpose of this file:** A standing handoff document. If a chat with Claude
> gets too long and starts degrading, paste this file as the first message in a
> new chat to resume exactly where you left off. Keep the "Current status"
> section updated at the end of each working day.

---

## Who I am and why I'm building this

I'm Vansh, a cloud infrastructure engineer (ex-Rackspace SRE on AWS, AWS certs,
IEEE paper on OpenStack benchmarking). I start an MSc in Computer Science at
Trinity College Dublin in September 2026. My north star is a Solutions/Cloud
Architect role; the realistic path is Cloud/Platform Engineer first, then
Architect. This is my first solo portfolio project, built in the ~2.5 months
before I relocate to Dublin, to show I can design and operate a platform rather
than just consume cloud services.

## How I want to work with Claude

- Guide me step by step. I run the commands, then study on my own to understand
  *why* we did what we did.
- For each new concept, tell me **what people commonly do** vs **the better
  way** and the tradeoff — so I have real material for my devlog learnings.
- Don't pre-solve every wall. A productive struggle teaches me; an unproductive
  one (a typo you could've flagged) just wastes time. Aim for the first.
- When something behaves contrary to expectation, isolate the variable and test
  empirically rather than spinning theories — verify environment facts early.
- I'm on a 16 GB M1 Pro MacBook, Docker Desktop, zero public-cloud cost. Keep
  everything local and free.
- I use VS Code and git. Commit at the end of each day; push to GitHub.

## What the project is

An Internal Developer Platform built on local Kubernetes (k3d). The problem it
solves: without a platform layer, every developer hand-writes Kubernetes YAML,
configures their own RBAC/monitoring/CI-CD, and routes every request through
ops. The platform makes deployment self-service, consistent, observable, and
safe, with the ops team setting guardrails once.

**Tech stack:** k3d · Kubernetes · Helm · Terraform · ArgoCD · Prometheus ·
Grafana · cert-manager · Traefik · (later) Backstage.

**Repo:** internal-dev-platform (public on GitHub).
**Repo layout:** docs/ (devlog.md + decisions/ ADRs), infra/ (Terraform),
apps/ (sample apps), platform/ (platform components: environments, cert-manager,
etc.), clusters/ (k3d config), scripts/.

## Roadmap (10-week / ~5-phase plan)

- **Phase 1 — Foundation:** k3d cluster + Terraform; ingress, cert-manager,
  namespaced dev/staging/prod environments with quotas. *(Days 1–2, mostly done)*
- **Phase 2 — GitOps:** ArgoCD with app-of-apps; CI pipeline (GitHub Actions →
  Docker build → image tag update) with prod promotion gate.
- **Phase 3 — Observability:** kube-prometheus-stack (Prometheus + Alertmanager
  + Grafana); custom PrometheusRules and alert routing; tracing (Tempo/Jaeger).
- **Phase 4 — Developer platform layer:** Backstage portal; self-service app
  onboarding via templates (the payoff — new service to all 3 envs in minutes).
- **Phase 5 — Polish:** ADRs finalized, README with architecture diagram, demo
  recording, CV bullet.

**Constraint note:** Backstage (Phase 4) and tracing (Phase 3) are stretch
goals. A complete Phases 1–3 + 6 with a great README beats a half-finished
Phase 4. 16 GB can't run every component at once — bring stacks up/down per phase.

## Current status — UPDATE THIS EACH DAY

**Last updated:** End of Day 3 (2026-06-20)

**Done so far:**
- Day 1: toolchain installed (Docker, k3d, helm, kubectl); repo scaffolded;
  git initialized; k3d cluster `devplatform` created (1 server + 2 agents);
  pushed to GitHub.
- Day 2: dev/staging/prod namespaces (declarative); ResourceQuotas +
  LimitRanges right-sized to real capacity; NetworkPolicy investigation (see
  below); Traefik inspected (bundled, not reinstalled); cert-manager installed
  via Helm; self-signed ClusterIssuer created and READY=True.
- Day 3: hello app deployed across all three envs via Kustomize

**Key finding from Day 2 (important context):** This cluster DOES enforce the
*deny* half of NetworkPolicy but NOT the *allow* (ingress `from`) half — proven
by a controlled dev-namespace experiment. Fix is to migrate to Calico (ADR
0003, status Proposed). NetworkPolicies were removed from active namespaces for
now; the YAML stays in the repo as intent.

**ADRs so far:** 0001 (use k3d), 0002 (namespace-per-environment isolation),
0003 (migrate to Calico — Proposed, not yet done).

**Next up (Day 4):** Setup ingress on the hello app to make the pod accessible via browser.
Start with setting up ArgoCD

**How to resume:** Read this file + docs/devlog.md + docs/decisions/ in the repo
to see exactly where things stand. The committed repo is the ground truth.