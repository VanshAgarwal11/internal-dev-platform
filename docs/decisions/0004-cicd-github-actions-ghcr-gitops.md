# ADR 0004: CI/CD via GitHub Actions + GHCR with GitOps deployment

**Status:** Accepted
**Date:** 2026-07-11

## Context
The platform needed a way to take application source code and get it running on
the cluster automatically. Until now, apps used a pre-built public image
(nginxdemos/hello); there was no path from "my code" to "running pod." We needed
CI (build the code into an image) connected to the existing GitOps CD (ArgoCD),
at zero cost, with the local k3d cluster as the deployment target.

## Decision
- **Build (CI):** GitHub Actions workflow builds a container image on every push
  that touches the app, using a multi-stage Dockerfile, and pushes to GitHub
  Container Registry (GHCR). Images are tagged both `:latest` and `:<commit-sha>`.
- **Registry:** GHCR — free for public repos, integrated with GitHub Actions via
  the built-in GITHUB_TOKEN (no stored registry credentials), and pullable by the
  local cluster once the package is public.
- **Deploy (CD):** unchanged — ArgoCD deploys from git. CI does NOT deploy; it
  builds and (in future) updates the image tag in git. ArgoCD reconciles from there.
- **Separation of CI and CD:** CI never has cluster credentials. It only produces
  an image and updates git. GitOps handles all cluster changes.

## Alternatives considered
- **Docker Hub instead of GHCR:** works, but a separate account/credentials and
  rate limits; GHCR's zero-config auth with GITHUB_TOKEN is cleaner for this setup.
- **CI deploys directly to the cluster (kubectl in the pipeline):** rejected — it
  would require giving GitHub Actions cluster credentials (a security/exposure
  risk, and impossible for a purely local cluster), and it bypasses GitOps, making
  the cluster state drift from git. Keeping CI→git→ArgoCD preserves git as the
  single source of truth.
- **Building images locally and pushing by hand:** not reproducible or automated;
  defeats the purpose of CI.

## Consequences
- Every image is traceable to the exact commit (SHA tag), which enables precise,
  auditable GitOps deploys.
- CI is secure by construction — no cluster access from the pipeline.
- GHCR packages are private by default; the package must be made public (or an
  imagePullSecret configured) for the local cluster to pull. Chose public for a
  portfolio project.
- **Open item:** the image-tag update in git is currently manual. To fully close
  the loop (code push → auto-deploy), a mechanism is needed to bump the tag in git
  automatically — either ArgoCD Image Updater, or a CI step that commits the new
  tag. This is deferred to the next session but does not change the architecture
  above.
