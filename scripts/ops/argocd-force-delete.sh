#!/usr/bin/env bash

# Version: 1
# Description: Forcefully deletes an Argo CD Application by removing its finalizers.
# Usage: ./scripts/ops/argocd-force-delete.sh <application-name> [namespace]

APP_NAME=$1
NAMESPACE=${2:-argocd} # Default to 'argocd' namespace if not provided

# Validate input
if [ -z "$APP_NAME" ]; then
  echo "Error: Application name is required."
  echo "Usage: $0 <application-name> [namespace]"
  exit 1
fi

echo "----------------------------------------------------------------"
echo "FORCE DELETE: Argo CD Application"
echo "Application: $APP_NAME"
echo "Namespace:   $NAMESPACE"
echo "----------------------------------------------------------------"

# Check if the application exists
if ! kubectl get application "$APP_NAME" -n "$NAMESPACE" &> /dev/null; then
  echo "❌ Application '$APP_NAME' not found in namespace '$NAMESPACE'."
  exit 1
fi

echo "⚠️  Attempting to remove finalizers (The Kill Switch)..."

# Patch the application to remove finalizers
kubectl patch application "$APP_NAME" \
  -n "$NAMESPACE" \
  -p '{"metadata":{"finalizers":[]}}' \
  --type=merge

if [ $? -eq 0 ]; then
  echo "✅ Success! Finalizers removed."
  echo "   Kubernetes should now delete the Application record immediately."
else
  echo "❌ Failed to patch application."
fi
