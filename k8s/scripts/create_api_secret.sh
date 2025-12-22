#!/usr/bin/env bash
# VERSION: 1
# Helper to create the encrypted API secret.

set -euo pipefail

echo "Running create_api_secret.sh"
SECRET_NAME="podverse-api-secret"
NAMESPACE="podverse-alpha"
OUTPUT_FILE="./k8s/secrets/podverse-api-secret.enc.yaml"

# --- INPUTS ---
echo "--- AUTHENTICATION ---"
read -s -p "Enter AUTH_JWT_SECRET (Random String): " AUTH_JWT_SECRET
echo ""
if [ -z "$AUTH_JWT_SECRET" ]; then echo "Error: JWT Secret required."; exit 1; fi

echo ""
echo "--- MAILER (Optional - Press Enter to skip) ---"
read -s -p "Enter MAILER_PASSWORD: " MAILER_PASSWORD
echo ""

# --- GENERATION ---
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "Generating and encrypting secret..."

TMP_FILE="$(mktemp -t "${SECRET_NAME}.XXXXXX.yaml")"
kubectl create secret generic "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --from-literal=AUTH_JWT_SECRET="${AUTH_JWT_SECRET}" \
    --from-literal=MAILER_PASSWORD="${MAILER_PASSWORD}" \
    --dry-run=client -o yaml > "$TMP_FILE"

sops --encrypt --encrypted-regex '^(data|stringData)$' \
    --input-type=yaml "$TMP_FILE" > "${OUTPUT_FILE}"

rm -f "$TMP_FILE"

echo "----------------------------------------------------"
echo "SUCCESS: Encrypted secret created at ${OUTPUT_FILE}"
echo "----------------------------------------------------"
echo "You can verify the values (if you have the key) by running:"
echo "sops -d ${OUTPUT_FILE}"