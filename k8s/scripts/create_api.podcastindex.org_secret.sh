#!/usr/bin/env bash
# VERSION: 1
# Helper to create the encrypted Workers secret (Podcast Index Keys).

set -euo pipefail

echo "Running create_workers_secret.sh"

# ENVIRONMENT INPUT
read -p "Enter environment [alpha]: " ENVIRONMENT
ENVIRONMENT="${ENVIRONMENT:-alpha}"

SECRET_NAME="podverse-api.podcastindex.org-opaque"
NAMESPACE="podverse-${ENVIRONMENT}"
OUTPUT_FILE="./k8s/secrets/podverse-${ENVIRONMENT}-api.podcastindex.org-opaque.enc.yaml"

# ------------------------------------------------------------------
# INPUTS
# ------------------------------------------------------------------
echo ""
echo "--- PODCAST INDEX API KEY---"
read -p "Enter PODCAST_INDEX_AUTH_KEY: " PI_AUTH
echo ""
if [ -z "$PI_AUTH" ]; then echo "Error: Auth Key required."; exit 1; fi

echo "--- PODCAST INDEX API SECRET---"
echo ""
read -s -p "Enter PODCAST_INDEX_SECRET_KEY: " PI_SECRET
echo ""
if [ -z "$PI_SECRET" ]; then echo "Error: Secret Key required."; exit 1; fi

# --- GENERATION ---
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "Generating and encrypting secret..."

TMP_FILE="$(mktemp -t "${SECRET_NAME}.XXXXXX.yaml")"
kubectl create secret generic "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --from-literal=PODCAST_INDEX_AUTH_KEY="${PI_AUTH}" \
    --from-literal=PODCAST_INDEX_SECRET_KEY="${PI_SECRET}" \
    --dry-run=client -o yaml > "$TMP_FILE"

sops --encrypt --encrypted-regex '^(data|stringData)$' \
    --input-type=yaml "$TMP_FILE" > "${OUTPUT_FILE}"

rm -f "$TMP_FILE"

echo "----------------------------------------------------"
echo "SUCCESS: Encrypted secret created at ${OUTPUT_FILE}"
echo "----------------------------------------------------"
echo "You can verify the values (if you have the key) by running:"
echo "sops -d ${OUTPUT_FILE}"