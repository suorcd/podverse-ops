#!/usr/bin/env bash
# VERSION: 1
# Helper to create the encrypted MQ secret.
# Includes aliases: ARTEMIS_* (for Broker) and MESSAGE_QUEUE_* (for Workers).

set -euo pipefail

echo "Running create_mq_secret.sh"
SECRET_NAME="podverse-mq-secret"
NAMESPACE="podverse-alpha"
OUTPUT_FILE="./k8s/secrets/podverse-mq-secret.enc.yaml"

# --- INPUTS ---
DEFAULT_USER="admin"
read -p "Enter MQ Username [${DEFAULT_USER}]: " INPUT_USER
MQ_USER="${INPUT_USER:-$DEFAULT_USER}"

echo ""
read -s -p "Enter MQ Password: " MQ_PASSWORD
echo ""
if [ -z "$MQ_PASSWORD" ]; then echo "Error: Password required."; exit 1; fi

# --- GENERATION ---
mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "Generating and encrypting secret..."

TMP_FILE="$(mktemp -t "${SECRET_NAME}.XXXXXX.yaml")"
kubectl create secret generic "${SECRET_NAME}" \
    --namespace "${NAMESPACE}" \
    --from-literal=ARTEMIS_USER="${MQ_USER}" \
    --from-literal=ARTEMIS_PASSWORD="${MQ_PASSWORD}" \
    \
    --from-literal=MESSAGE_QUEUE_USERNAME="${MQ_USER}" \
    --from-literal=MESSAGE_QUEUE_PASSWORD="${MQ_PASSWORD}" \
    \
    --dry-run=client -o yaml > "$TMP_FILE"

sops --encrypt --encrypted-regex '^(data|stringData)$' \
    --input-type=yaml "$TMP_FILE" > "${OUTPUT_FILE}"

rm -f "$TMP_FILE"

echo "----------------------------------------------------"
echo "SUCCESS: Encrypted secret created at ${OUTPUT_FILE}"
echo "----------------------------------------------------"
echo "You can verify the values (if you have the key) by running:"
echo "sops -d ${OUTPUT_FILE}"