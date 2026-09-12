#!/usr/bin/env bash

set -euo pipefail

REPO="AsaadFethallah/SecureBoard"
ARTIFACT_NAME="secureboard-production-manifests"
EXPECTED_CONTEXT="kind-secureboard"
NAMESPACE="secureboard"
LOCK_FILE="/tmp/secureboard-deploy.lock"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <github-run-id>"
  exit 2
fi

RUN_ID="$1"
ARTIFACT_DIR="/tmp/secureboard-authorized-${RUN_ID}"

for COMMAND in gh jq kubectl sha256sum curl flock; do
  if ! command -v "$COMMAND" >/dev/null 2>&1; then
    echo "FAIL: required command not found: $COMMAND"
    exit 1
  fi
done

echo "=========================================="
echo "SecureBoard controlled release deployment"
echo "Run ID: $RUN_ID"
echo "=========================================="

echo
echo "=== 1. VERIFY GITHUB RELEASE RUN ==="

RUN_JSON=$(gh run view "$RUN_ID" \
  -R "$REPO" \
  --json conclusion,headBranch,event,headSha,name)

echo "$RUN_JSON" | jq .

if ! echo "$RUN_JSON" | jq -e '
  .conclusion == "success"
  and .headBranch == "main"
  and .event == "push"
  and .name == "SecureBoard CI"
' >/dev/null; then
  echo "FAIL: GitHub run is not a successful main push"
  exit 1
fi

RELEASE_SHA=$(echo "$RUN_JSON" | jq -r '.headSha')

if ! printf '%s\n' "$RELEASE_SHA" \
  | grep -Eq '^[a-f0-9]{40}$'; then

  echo "FAIL: invalid release commit SHA"
  exit 1
fi

echo "PASS: trusted GitHub release run"
echo "Release commit: $RELEASE_SHA"


echo
echo "=== 2. DOWNLOAD AUTHORIZED ARTIFACT ==="

rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

gh run download "$RUN_ID" \
  -R "$REPO" \
  --name "$ARTIFACT_NAME" \
  --dir "$ARTIFACT_DIR"

cd "$ARTIFACT_DIR"

EXPECTED_FILES=(
  secureboard-prod.yaml
  secureboard-prod-foundation.yaml
  secureboard-prod-migration.yaml
  secureboard-prod-application.yaml
  secureboard-production-manifests.sha256
)

for FILE in "${EXPECTED_FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "FAIL: required artifact file missing: $FILE"
    exit 1
  fi
done

FILE_COUNT=$(find . \
  -maxdepth 1 \
  -type f \
  | wc -l)

if [ "$FILE_COUNT" -ne 5 ]; then
  echo "FAIL: unexpected artifact file count: $FILE_COUNT"
  exit 1
fi

echo "PASS: authorized artifact downloaded"


echo
echo "=== 3. VERIFY ARTIFACT INTEGRITY ==="

if [ "$(wc -l < secureboard-production-manifests.sha256)" -ne 4 ]; then
  echo "FAIL: checksum manifest must contain exactly four records"
  exit 1
fi

sha256sum -c \
  secureboard-production-manifests.sha256

echo "PASS: all authorized manifest hashes verified"


echo
echo "=== 4. VERIFY RELEASE IMAGE IDENTITY ==="

IMAGE_REFS=$(grep -h \
  'image: ghcr.io/asaadfethallah/secureboard@sha256:' \
  secureboard-prod.yaml \
  secureboard-prod-migration.yaml \
  secureboard-prod-application.yaml \
  | awk '{print $2}' \
  | sort -u)

IMAGE_REF_COUNT=$(printf '%s\n' "$IMAGE_REFS" \
  | grep -c '^ghcr.io/' || true)

if [ "$IMAGE_REF_COUNT" -ne 1 ]; then
  echo "FAIL: manifests do not reference exactly one SecureBoard image identity"
  exit 1
fi

AUTHORIZED_IMAGE="$IMAGE_REFS"

if ! printf '%s\n' "$AUTHORIZED_IMAGE" \
  | grep -Eq '^ghcr\.io/asaadfethallah/secureboard@sha256:[a-f0-9]{64}$'; then

  echo "FAIL: malformed authorized image identity"
  exit 1
fi

if grep -Fq \
  'ghcr.io/asaadfethallah/secureboard@' \
  secureboard-prod-foundation.yaml; then

  echo "FAIL: SecureBoard application image exists in foundation"
  exit 1
fi

if grep -Fq \
  'sha256:0000000000000000000000000000000000000000000000000000000000000000' \
  secureboard-prod*.yaml; then

  echo "FAIL: zero digest placeholder detected"
  exit 1
fi

echo "PASS: immutable release image accepted"
echo "Image: $AUTHORIZED_IMAGE"


echo
echo "=== 5. VERIFY KUBERNETES TARGET ==="

CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
  echo "FAIL: refusing deployment to context: $CURRENT_CONTEXT"
  echo "Expected: $EXPECTED_CONTEXT"
  exit 1
fi

kubectl get node >/dev/null

echo "PASS: context=$CURRENT_CONTEXT"


echo
echo "=== 6. VERIFY SECRET PREREQUISITES ==="

kubectl get secret \
  secureboard-secrets \
  -n "$NAMESPACE" \
  >/dev/null

kubectl get secret \
  secureboard-secrets \
  -n "$NAMESPACE" \
  -o json \
  | jq -e '
      .data
      | has("POSTGRES_USER")
      and has("POSTGRES_PASSWORD")
      and has("POSTGRES_DB")
      and has("DATABASE_URL")
      and has("JWT_SECRET")
    ' >/dev/null

echo "PASS: required secret and keys exist"


echo
echo "=== 7. SERVER-SIDE PREFLIGHT ==="

for MANIFEST in \
  secureboard-prod-foundation.yaml \
  secureboard-prod-migration.yaml \
  secureboard-prod-application.yaml
do
  kubectl apply \
    --dry-run=server \
    -f "$MANIFEST" \
    >/dev/null

  echo "PASS: $MANIFEST"
done


echo
echo "=== 8. ACQUIRE DEPLOYMENT LOCK ==="

(
  flock -n 9 || {
    echo "FAIL: another SecureBoard deployment is running"
    exit 1
  }

  echo "PASS: deployment lock acquired"


  echo
  echo "=== 9. REMOVE PREVIOUS APPLICATION ==="

  kubectl delete deployment \
    secureboard-api \
    -n "$NAMESPACE" \
    --ignore-not-found=true \
    --wait=true

  echo "PASS: previous application workload removed"


  echo
  echo "=== 10. REMOVE PREVIOUS MIGRATION JOB ==="

  kubectl delete job \
    secureboard-db-migrate \
    -n "$NAMESPACE" \
    --ignore-not-found=true \
    --wait=true

  echo "PASS: previous migration Job removed"


  echo
  echo "=== 11. APPLY FOUNDATION ==="

  kubectl apply \
    -f secureboard-prod-foundation.yaml

  kubectl rollout status \
    deployment/postgres \
    -n "$NAMESPACE" \
    --timeout=180s

  kubectl wait \
    --for=condition=Ready \
    pod \
    -l app=postgres \
    -n "$NAMESPACE" \
    --timeout=180s

  echo "PASS: foundation ready"


  echo
  echo "=== 12. RUN DATABASE MIGRATION ==="

  kubectl apply \
    -f secureboard-prod-migration.yaml

  if ! kubectl wait \
    --for=condition=complete \
    job/secureboard-db-migrate \
    -n "$NAMESPACE" \
    --timeout=300s
  then
    echo "FAIL: database migration did not complete"

    kubectl get job \
      secureboard-db-migrate \
      -n "$NAMESPACE" \
      -o wide || true

    kubectl get pods \
      -n "$NAMESPACE" \
      -l app=secureboard-migrations || true

    echo "Migration logs:"
    kubectl logs \
      -n "$NAMESPACE" \
      job/secureboard-db-migrate \
      --tail=100 || true

    exit 1
  fi

  echo "PASS: database migration complete"


  echo
  echo "=== 13. DEPLOY APPLICATION ==="

  kubectl apply \
    -f secureboard-prod-application.yaml

  kubectl rollout status \
    deployment/secureboard-api \
    -n "$NAMESPACE" \
    --timeout=300s

  kubectl wait \
    --for=condition=Ready \
    pod \
    -l app=secureboard-api \
    -n "$NAMESPACE" \
    --timeout=180s

  echo "PASS: application rollout complete"


  echo
  echo "=== 14. VERIFY DEPLOYED IMAGE ==="

  DEPLOYED_IMAGE=$(kubectl get deployment \
    secureboard-api \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[?(@.name=="api")].image}')

  echo "Authorized: $AUTHORIZED_IMAGE"
  echo "Deployed:   $DEPLOYED_IMAGE"

  if [ "$DEPLOYED_IMAGE" != "$AUTHORIZED_IMAGE" ]; then
    echo "FAIL: deployed image differs from authorized image"
    exit 1
  fi

  echo "PASS: exact authorized image deployed"


  echo
  echo "=== 15. HEALTH CHECK ==="

  PORT_FORWARD_LOG="/tmp/secureboard-port-forward-${RUN_ID}.log"

  rm -f "$PORT_FORWARD_LOG"

  kubectl port-forward \
    --address 127.0.0.1 \
    -n "$NAMESPACE" \
    service/secureboard-api \
    18000:8000 \
    >"$PORT_FORWARD_LOG" \
    2>&1 &

  PF_PID=$!

  cleanup_port_forward() {
    kill "$PF_PID" 2>/dev/null || true
  }

  trap cleanup_port_forward EXIT

  PORT_FORWARD_READY=0

  for _ in $(seq 1 40); do
    if ! kill -0 "$PF_PID" 2>/dev/null; then
      echo "FAIL: kubectl port-forward terminated unexpectedly"
      cat "$PORT_FORWARD_LOG" || true
      exit 1
    fi

    if grep -Fq \
      'Forwarding from 127.0.0.1:18000' \
      "$PORT_FORWARD_LOG"; then

      PORT_FORWARD_READY=1
      break
    fi

    sleep 0.25
  done

  if [ "$PORT_FORWARD_READY" -ne 1 ]; then
    echo "FAIL: port-forward did not become ready"
    cat "$PORT_FORWARD_LOG" || true
    exit 1
  fi

  echo "PASS: port-forward ready"

  HEALTH_OK=0

  for _ in $(seq 1 30); do
    if curl -fsS \
      http://127.0.0.1:18000/health \
      2>/dev/null \
      | jq -e '.status == "ok"' \
      >/dev/null 2>&1
    then
      HEALTH_OK=1
      break
    fi

    sleep 2
  done

  if [ "$HEALTH_OK" -ne 1 ]; then
    echo "FAIL: application health check failed"
    cat "$PORT_FORWARD_LOG" || true
    exit 1
  fi

  echo "PASS: /health returned status=ok"


  echo
  echo "=========================================="
  echo "DEPLOYMENT SUCCESS"
  echo "=========================================="
  echo "Run:    $RUN_ID"
  echo "Commit: $RELEASE_SHA"
  echo "Image:  $AUTHORIZED_IMAGE"
  echo

  kubectl get deployment,job,pod \
    -n "$NAMESPACE"

) 9>"$LOCK_FILE"
