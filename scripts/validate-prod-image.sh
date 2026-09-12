#!/usr/bin/env bash

set -euo pipefail

IMAGE_DIGEST="${1:-}"

PLACEHOLDER_DIGEST="sha256:0000000000000000000000000000000000000000000000000000000000000000"

if [[ -z "$IMAGE_DIGEST" ]]; then
    echo "ERROR: image digest was not provided"
    exit 1
fi

if [[ "$IMAGE_DIGEST" == "$PLACEHOLDER_DIGEST" ]]; then
    echo "ERROR: placeholder digest is not deployable"
    exit 1
fi

if [[ ! "$IMAGE_DIGEST" =~ ^sha256:[a-f0-9]{64}$ ]]; then
    echo "ERROR: invalid image digest format"
    exit 1
fi

echo "PASS: production image digest is valid"
