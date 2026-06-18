# Internal Developer Platform (IDP)

A self-service platform built on Kubernetes that lets developers deploy,
monitor, and operate services without writing raw YAML or filing tickets.

> **Status:** In active development. Built as a hands-on platform-engineering
> project. See [`docs/devlog.md`](docs/devlog.md) for the build journal and
> [`docs/decisions/`](docs/decisions/) for architecture decisions.

## The problem
Without a platform layer, every developer hand-writes Kubernetes manifests,
configures their own RBAC, monitoring, and CI/CD, and routes every request
through the ops team. This is slow, inconsistent, and doesn't scale.

## What this builds
A platform that makes deployment self-service, consistent, observable, and safe.

## Architecture
(diagram coming in a later phase)

## Tech stack
k3d · Kubernetes · Helm · Terraform · ArgoCD · Prometheus · Grafana

## Running locally
(setup instructions coming once the cluster scripts are stable)
