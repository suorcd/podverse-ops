#!/usr/bin/env bash
# VERSION: 1
# Filename: create_valkey_secret.sh
# Helper to create the encrypted Valkey secret.
# Maps inputs to VALKEY_PASSWORD (and generic PASSWORD for compatibility).

set -euo pipefail

echo "Running create_valkey_secret.sh"

# ENVIRONMENT INPUT
read -p "Enter environment [alpha]: " ENVIRONMENT
ENVIRONMENT="${ENVIRONMENT:-alpha}"

# Matches the secret name defined in podverse-alpha.yaml
SECRET_NAME="podverse-keyvaldb-opaque"
NAMESPACE="podverse-${ENVIRONMENT}"
OUTPUT_FILE="./k8s/secrets/podverse-${ENVIRONMENT}-keyvaldb-opaque.enc.yaml"

# ------------------------------------------------------------------
# INPUTS
# ------------------------------------------------------------------
echo ""
echo "--- SENSITIVE INPUTS ---"
read -s -p "Enter Valkey Password: " VALKEY_PASSWORD
echo ""
if [ -z "$VALKEY_PASSWORD" ]; then echo "Error: Password required."; exit 1; fi

# --- GENERATION ---
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "Generating and encrypting secret..."

TMP_FILE="$(mktemp -t "${SECRET_NAME}.XXXXXX.yaml")"

# We create both VALKEY_PASSWORD and PASSWORD to ensure compatibility 
# with various images or custom entrypoint scripts.
kubectl create secret generic "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --from-literal=VALKEY_PASSWORD="${VALKEY_PASSWORD}" \
    --from-literal=PASSWORD="${VALKEY_PASSWORD}" \
    --dry-run=client -o yaml > "$TMP_FILE"

sops --encrypt --encrypted-regex '^(data|stringData)$' \
    --input-type=yaml "$TMP_FILE" > "${OUTPUT_FILE}"

rm -f "$TMP_FILE"

echo "----------------------------------------------------"
echo "SUCCESS: Encrypted secret created at ${OUTPUT_FILE}"
echo "----------------------------------------------------"
echo "You can verify the values (if you have the key) by running:"
echo "sops -d ${OUTPUT_FILE}"
echo ""
echo "You can apply the values (if you have the key) by running:"
echo "sops -d ${OUTPUT_FILE} | kubectl apply -f -"