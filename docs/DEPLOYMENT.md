# SecureBoard Deployment Architecture

## Overview

SecureBoard uses a release-oriented DevSecOps pipeline.

The CI pipeline builds the application once, performs security verification,
publishes the immutable container image, signs the release, verifies
provenance, and generates authorized Kubernetes deployment artifacts.

Deployment consumes those authorized artifacts instead of rebuilding or
rerendering the release locally.

---

## CI Security Pipeline

The SecureBoard CI pipeline includes:

- Automated application tests
- Semgrep SAST
- Gitleaks secret scanning
- Trivy dependency scanning
- Trivy container image scanning
- Checkov Infrastructure-as-Code scanning
- OWASP ZAP active DAST
- CycloneDX SBOM generation
- Build provenance attestation
- Cosign keyless artifact signing
- GHCR immutable image publication
- OCI provenance
- Cosign container image signing
- Deployment trust-policy enforcement

The container image is built once and reused throughout the security pipeline.

---

## Release Identity

Production releases use an immutable GHCR reference:

    ghcr.io/asaadfethallah/secureboard@sha256:<digest>

The deployment trust policy verifies:

1. Immutable image identity
2. Cosign signature
3. GitHub OIDC signing identity
4. Build provenance
5. Source repository
6. Source branch
7. Production Kustomize rendering
8. Deployment topology
9. Checkov security policy
10. Manifest integrity hashes

---

## Authorized Deployment Artifacts

A successful release generates:

    secureboard-prod.yaml
    secureboard-prod-foundation.yaml
    secureboard-prod-migration.yaml
    secureboard-prod-application.yaml
    secureboard-production-manifests.sha256

The phase manifests are integrity-protected using SHA256 records.

The deployment process consumes these exact artifacts rather than generating
new manifests from the local repository.

---

## Ordered Deployment

SecureBoard uses three ordered deployment phases.

### Phase 1 - Foundation

The foundation phase contains the infrastructure required before application
migration or rollout.

It includes resources such as:

- Namespace
- PostgreSQL
- Persistent storage
- Services
- ConfigMap
- NetworkPolicies

It contains neither the SecureBoard API Deployment nor the migration Job.

PostgreSQL must become Ready before the deployment proceeds.

### Phase 2 - Migration

The migration phase contains the dedicated Alembic migration Job.

It does not deploy the API or PostgreSQL Deployment.

The deployment stops if the migration Job does not complete successfully.

### Phase 3 - Application

The application phase deploys the SecureBoard API only after the migration
phase succeeds.

The deployment then verifies:

- Kubernetes rollout
- Pod readiness
- Exact immutable image identity
- `/health` application endpoint

---

## Fail-Closed Deployment Executor

The deployment implementation is:

    scripts/deploy-kind-release.sh

Usage:

    ./scripts/deploy-kind-release.sh <successful-main-ci-run-id>

Before mutating the cluster, the deployer verifies:

- GitHub CI run status
- Main branch identity
- Push event
- SecureBoard CI workflow identity
- Authorized artifact availability
- Manifest SHA256 integrity
- Immutable GHCR digest
- Kubernetes context
- Required Kubernetes Secret keys
- Server-side Kubernetes admission

The deployer also uses a local deployment lock to prevent concurrent
deployments.

If migration, image identity, rollout, or application health verification
fails, deployment stops.

---

## Kubernetes Security Controls

SecureBoard Kubernetes workloads use security controls including:

- Non-root containers
- Explicit runtime UIDs
- Seccomp RuntimeDefault
- Read-only root filesystems
- Disabled privilege escalation
- Dropped Linux capabilities
- Resource requests and limits
- Disabled automatic ServiceAccount token mounting
- Secrets mounted as files
- Pod Security Admission restricted policy
- Kubernetes NetworkPolicies
- Digest-pinned production images

PostgreSQL uses its dedicated vendor runtime UID/GID.

---

## Manual CD Workflow

The repository includes:

    .github/workflows/cd-kind.yml

The workflow is intentionally manual and uses:

    workflow_dispatch

It is designed for a dedicated self-hosted runner with the labels:

    self-hosted
    linux
    x64
    secureboard-kind

The self-hosted runner is intentionally not installed as part of this
development environment.

A production implementation should protect such a runner carefully and
restrict who can trigger deployments.

---

## Local Development Cluster

The development environment used a local kind cluster named:

    secureboard

with Kubernetes context:

    kind-secureboard

The local cluster is a development/lab environment and is not a production
deployment target.

---

## Current Project Boundary

The project demonstrates the complete DevSecOps release architecture through:

    source
      -> tests
      -> security scanning
      -> build-once image
      -> SBOM
      -> provenance
      -> signing
      -> immutable registry release
      -> deployment authorization
      -> phased Kubernetes deployment
      -> runtime verification

The self-hosted GitHub Actions deployment runner is intentionally left as a
future infrastructure integration step.
