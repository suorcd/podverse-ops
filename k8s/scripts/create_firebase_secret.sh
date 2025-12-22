#!/usr/bin/env bash
# VERSION: 1
# Helper to create the encrypted Firebase secret from a local JSON file.

set -euo pipefail

echo "Running create_firebase_secret.sh"

# ENVIRONMENT INPUT
read -p "Enter environment [alpha]: " ENVIRONMENT
ENVIRONMENT="${ENVIRONMENT:-alpha}"

SECRET_NAME="podverse-${ENVIRONMENT}-workers-firebase-opaque"
NAMESPACE="podverse-${ENVIRONMENT}"
OUTPUT_FILE="./k8s/secrets/podverse-${ENVIRONMENT}-workers-firebase-opaque.enc.yaml"

# --- INPUTS ---
echo "Please enter the path to your 'firebase-key.json' file:"
read -e -p "Path: " FILE_PATH

# Verify file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found at $FILE_PATH"
    exit 1
fi

# --- GENERATION ---
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "Reading file and encrypting secret..."

# We use --from-file to load the entire JSON content
TMP_FILE="$(mktemp -t "${SECRET_NAME}.XXXXXX.yaml")"
kubectl create secret generic "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --from-file=firebase-key.json="${FILE_PATH}" \
    --dry-run=client -o yaml > "$TMP_FILE"

sops --encrypt --encrypted-regex '^(data|stringData)$' \
    --input-type=yaml "$TMP_FILE" > "${OUTPUT_FILE}"

rm -f "$TMP_FILE"

echo "----------------------------------------------------"
echo "SUCCESS: Encrypted secret created at ${OUTPUT_FILE}"
echo "----------------------------------------------------"
echo "You can verify the values (if you have the key) by running:"
echo "sops -d ${OUTPUT_FILE}"