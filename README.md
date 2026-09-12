# SecureBoard

## Hi, I'm Asaad FETHALLAH!

SecureBoard is a hands-on DevSecOps learning project built around a FastAPI application.

The project progressively implements:

- Automated testing
- Docker
- CI/CD
- SAST
- Secret scanning
- Dependency scanning
- Container security
- Infrastructure as Code
- Kubernetes
- DAST
- Security gates
- Supply-chain security
- SBOM generation
- Build provenance
- Cosign signing
- Immutable container releases
- Kubernetes deployment authorization
- Fail-closed deployment workflows

---

## Current Stack

- Python
- FastAPI
- Uvicorn
- Pytest
- PostgreSQL
- SQLAlchemy
- Alembic
- Docker
- GitHub Actions
- Kubernetes
- kind
- Kustomize

---

## Local Development

Create the virtual environment:

```bash
python3 -m venv .venv
```

Activate it:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the tests:

```bash
python -m pytest -v
```

Run the API:

```bash
uvicorn app.main:app --reload
```

The health endpoint is available at:

```text
GET /health
```

Expected response:

```json
{
  "status": "ok"
}
```

---

## DevSecOps Pipeline

SecureBoard implements a complete CI security pipeline with:

- Automated application tests
- Semgrep SAST
- Gitleaks secret scanning
- Trivy dependency scanning
- Trivy container image scanning
- Checkov Infrastructure-as-Code scanning
- OWASP ZAP active DAST
- CycloneDX SBOM generation
- Build provenance attestation
- Cosign keyless signing
- GHCR immutable image publishing
- OCI provenance
- Kubernetes deployment trust-policy enforcement

The application container image is built once and reused throughout the security pipeline.

---

## Supply-Chain Security

Production releases are published using immutable GHCR references:

```text
ghcr.io/asaadfethallah/secureboard@sha256:<digest>
```

The release pipeline verifies:

- Immutable image identity
- Cosign signature
- GitHub OIDC identity
- Build provenance
- Repository identity
- Branch identity
- Production Kubernetes manifests
- Kubernetes security policy
- Deployment topology
- Manifest SHA256 integrity

---

## Kubernetes Security

SecureBoard Kubernetes workloads include several hardening controls:

- Non-root containers
- Explicit runtime UIDs
- `seccompProfile: RuntimeDefault`
- Read-only root filesystems
- Disabled privilege escalation
- Dropped Linux capabilities
- Resource requests and limits
- Disabled automatic ServiceAccount token mounting
- Kubernetes Secrets mounted as files
- Pod Security Admission restricted policy
- NetworkPolicies
- Digest-pinned production images

PostgreSQL runs using its dedicated non-root vendor account.

---

## Ordered Kubernetes Deployment

Production deployment is separated into three ordered phases:

```text
Foundation
    ↓
PostgreSQL Ready
    ↓
Database Migration
    ↓
Migration Complete
    ↓
Application
    ↓
Rollout Verification
    ↓
Health Check
```

### Phase 1 - Foundation

The foundation phase prepares the resources required before application deployment.

It includes resources such as:

- Namespace
- PostgreSQL
- Persistent storage
- Services
- ConfigMap
- NetworkPolicies

The SecureBoard API Deployment and migration Job are not deployed in this phase.

PostgreSQL must become Ready before the deployment continues.

### Phase 2 - Migration

A dedicated Kubernetes Job runs:

```bash
alembic upgrade head
```

The migration phase does not deploy the API or PostgreSQL Deployment.

If the migration Job does not complete successfully, the deployment stops.

### Phase 3 - Application

The SecureBoard API is deployed only after a successful database migration.

The deployment then verifies:

- Kubernetes rollout
- Pod readiness
- Exact immutable image identity
- Application `/health` endpoint

---

## Authorized Deployment Artifacts

A successful release produces:

```text
secureboard-prod.yaml
secureboard-prod-foundation.yaml
secureboard-prod-migration.yaml
secureboard-prod-application.yaml
secureboard-production-manifests.sha256
```

The deployment process consumes these exact CI-authorized artifacts instead of rebuilding or rerendering the release locally.

---

## Verified Deployment Executor

The repository includes:

```text
scripts/deploy-kind-release.sh
```

Usage:

```bash
./scripts/deploy-kind-release.sh <successful-main-ci-run-id>
```

Before modifying the cluster, the deployer verifies:

- Successful GitHub CI run
- `main` branch identity
- Push event
- SecureBoard CI workflow identity
- Authorized artifact availability
- Manifest SHA256 integrity
- Immutable GHCR image digest
- Kubernetes context
- Required Secret keys
- Server-side Kubernetes admission
- Deployment concurrency lock

The deployment is fail-closed.

If migration, image verification, rollout, or application health verification fails, the deployment stops.

---

## Manual CD Workflow

The repository also contains:

```text
.github/workflows/cd-kind.yml
```

The workflow is designed as a manual deployment workflow using:

```yaml
workflow_dispatch
```

It is intended for a dedicated self-hosted runner with access to the local Kubernetes environment.

The expected runner labels are:

```text
self-hosted
linux
x64
secureboard-kind
```

The self-hosted runner is intentionally not included as part of the current development environment.

---

## CI/CD Architecture

```text
Source Code
    ↓
Automated Tests
    ↓
SAST / Secret Scan / Dependency Scan
    ↓
Build Canonical Container Image
    ↓
Container Image Scan
    ↓
DAST
    ↓
SBOM Generation
    ↓
Build Provenance
    ↓
Cosign Signing
    ↓
Immutable GHCR Release
    ↓
Deployment Trust Policy
    ↓
Authorized Kubernetes Manifests
    ↓
Foundation
    ↓
PostgreSQL Ready
    ↓
Database Migration
    ↓
Migration Complete
    ↓
Application Deployment
    ↓
Runtime Verification
```

---

## Security Pipeline Overview

### Automated Testing

Application tests are executed with Pytest before release.

### SAST

Semgrep analyzes the source code for insecure coding patterns.

### Secret Scanning

Gitleaks scans the repository and Git history for accidentally committed secrets.

### Dependency Scanning

Trivy scans application dependencies for known vulnerabilities.

### Container Security

The canonical container image is scanned before publication.

### Infrastructure as Code

Checkov validates Kubernetes and infrastructure configuration against security policies.

### DAST

OWASP ZAP performs active API security testing against an ephemeral SecureBoard environment.

### SBOM

Syft generates a CycloneDX Software Bill of Materials for the canonical container image.

### Provenance

The pipeline creates build provenance attestation linking the release artifact to its source and workflow.

### Signing

Cosign keyless signing uses GitHub OIDC to sign release artifacts and immutable GHCR images.

### Deployment Authorization

The deployment trust policy verifies the image signature, provenance, immutable digest, Kubernetes manifests, security policy, deployment topology, and integrity hashes before the release is authorized.

---

## Build-Once Strategy

SecureBoard follows a build-once approach.

The container image is built once and exported as the canonical image artifact.

The same artifact is then reused for:

- Container vulnerability scanning
- DAST
- SBOM generation
- Provenance
- Signing
- GHCR publication

This reduces the risk of differences between the image that was tested and the image that is eventually released.

---

## Production Image Identity

Production Kubernetes manifests use a digest-pinned image reference:

```text
ghcr.io/asaadfethallah/secureboard@sha256:<digest>
```

Mutable tags are not used as the deployment identity.

The CI pipeline replaces the production placeholder digest only after the release image has been published and verified.

---

## Deployment Trust Policy

The release policy validates:

1. The container image uses an immutable digest
2. The image was signed using Cosign
3. The signing identity matches the expected GitHub workflow
4. Build provenance matches the repository and source branch
5. Kubernetes production manifests use the authorized digest
6. Deployment topology matches the expected phases
7. Checkov security policies pass
8. Only the expected Checkov exceptions exist
9. SHA256 integrity records are generated for all production manifests

Only after these checks pass is deployment considered authorized.

---

## Deployment Phases

The CI pipeline authorizes four Kubernetes manifests:

```text
secureboard-prod.yaml
secureboard-prod-foundation.yaml
secureboard-prod-migration.yaml
secureboard-prod-application.yaml
```

The full manifest represents the complete production state.

The three phase manifests are used by the controlled deployment process.

### Foundation Topology

Expected workload topology:

```text
PostgreSQL Deployment: 1
SecureBoard API:        0
Migration Job:          0
```

### Migration Topology

Expected workload topology:

```text
PostgreSQL Deployment: 0
SecureBoard API:        0
Migration Job:          1
```

### Application Topology

Expected workload topology:

```text
PostgreSQL Deployment: 0
SecureBoard API:        1
Migration Job:          0
```

This ensures the database is available before migrations run and the application is deployed only after migrations succeed.

---

## Network Security

SecureBoard uses Kubernetes NetworkPolicies to restrict traffic between workloads.

The policies control communication between:

- SecureBoard API
- PostgreSQL
- Migration Job
- Kubernetes DNS

The PostgreSQL workload accepts database traffic only from the required SecureBoard workloads.

---

## Pod Security

The SecureBoard namespace uses Kubernetes Pod Security Admission with the restricted policy.

The application and migration workloads are configured with security controls including:

```text
runAsNonRoot
readOnlyRootFilesystem
allowPrivilegeEscalation: false
seccompProfile: RuntimeDefault
capabilities.drop: ALL
automountServiceAccountToken: false
```

---

## Secrets

Sensitive configuration is not committed to Git.

The application supports loading secrets from mounted files using variables such as:

```text
DATABASE_URL_FILE
JWT_SECRET_FILE
```

Kubernetes Secrets are mounted into containers as files instead of exposing sensitive values directly in application environment variables where possible.

---

## Database Migrations

Alembic database migrations run in a dedicated Kubernetes Job.

This avoids running migrations independently in every API replica.

The deployment order is:

```text
PostgreSQL Ready
    ↓
Migration Job
    ↓
Migration Complete
    ↓
API Deployment
```

A migration failure prevents the application deployment from proceeding.

---

## Deployment Integrity

Each authorized production manifest is protected by SHA256 integrity records:

```text
secureboard-production-manifests.sha256
```

Before deployment, the deployer runs:

```bash
sha256sum -c secureboard-production-manifests.sha256
```

If any authorized manifest has changed, deployment stops.

---

## Deployment Concurrency

The local release deployer uses a deployment lock to prevent simultaneous SecureBoard deployments.

This avoids multiple deployments modifying the same migration Job or Kubernetes workloads at the same time.

---

## Runtime Verification

After deployment, SecureBoard verifies:

- PostgreSQL readiness
- Migration completion
- API rollout status
- Pod readiness
- Exact deployed image digest
- `/health` response

The deployed image must exactly match the image authorized by the release pipeline.

---

## Local Kubernetes Environment

The development environment used a local kind cluster named:

```text
secureboard
```

The expected Kubernetes context is:

```text
kind-secureboard
```

The local kind cluster is a development and learning environment, not a production infrastructure platform.

---

## Repository Structure

```text
SecureBoard/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── cd-kind.yml
├── alembic/
├── app/
├── docs/
│   └── DEPLOYMENT.md
├── k8s/
│   ├── base/
│   └── overlays/
│       ├── local/
│       ├── prod/
│       ├── prod-foundation/
│       ├── prod-migration/
│       └── prod-application/
├── scripts/
│   ├── deploy-kind-release.sh
│   └── validate-prod-image.sh
├── tests/
├── Dockerfile
├── alembic.ini
├── requirements.txt
└── README.md
```

---

## Project Goal

SecureBoard was built as a practical DevSecOps learning project to understand how development, security, CI/CD, containers, Kubernetes, and software supply-chain security fit together in a real release workflow.

The project demonstrates the lifecycle from source code to a security-verified and authorized Kubernetes release.

The final architecture covers:

```text
Development
    ↓
Testing
    ↓
Security Scanning
    ↓
Containerization
    ↓
Supply-Chain Security
    ↓
Release Authorization
    ↓
Kubernetes Deployment
    ↓
Runtime Verification
```

SecureBoard is primarily a learning and portfolio project designed to demonstrate modern DevSecOps concepts in a practical end-to-end implementation.
