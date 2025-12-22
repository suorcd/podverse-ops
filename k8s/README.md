# podverse-ops

Deployment scripts and Kubernetes manifests for the Podverse ecosystem.

## Architecture Overview

This repository uses a GitOps workflow (via ArgoCD) to manage the Podverse infrastructure on a K3s cluster.

### Layers

1.  **Infrastructure (System)**: Cluster-wide services that must exist *before* applications are deployed.
    * **Traefik**: Ingress Controller (Ports 80/443).
    * **Cert-Manager**: Automates SSL certificates via Let's Encrypt.
    * **ClusterIssuers**: Validates domain ownership (DigitalOcean/Cloudflare).
    * **StorageClass**: Local Path Provisioner (default in K3s).

2.  **Applications (Tenants)**: The actual Podverse environments.
    * **Alpha**: `podverse-alpha` namespace. Bleeding edge / Dev.
    * **Beta/Prod**: (Future) Stable environments.

## Prerequisites

Before deploying the Application manifests (in `k8s/alpha`), ensure the following Infrastructure is running:

1.  **K3s Cluster**: Up and running (e.g., on NixOS/Proxmox).
2.  **Cert-Manager**: Installed in `cert-manager` namespace.
    * *Verification*: `kubectl get pods -n cert-manager`
3.  **ClusterIssuer**: configured for your DNS provider (e.g., `letsencrypt-prod`).
    * *Verification*: `kubectl get clusterissuer letsencrypt-prod`
4.  **Secrets**:
    * Cloud Provider Tokens (e.g., `digitalocean-api-token-secret`) must be present in the `cert-manager` namespace for DNS challenges.

## Directory Structure

* `k8s/`
    * `system/`: Cluster-wide configs (Traefik defaults, etc.).
    * `alpha/`: Manifests for the Alpha environment.
        * `00-namespace.yaml`: Isolation boundary.
        * `api/`, `web/`, `db/`, `mq/`, `workers/`: Component manifests.
    * `scripts/`: Helper scripts to generate sealed secrets.

## Getting Started (Alpha Environment)

### 1. Generate Secrets
We use SOPS to encrypt secrets. Run the helper scripts in `k8s/scripts/` to generate the required encrypted files:

```bash
# Example
./k8s/scripts/create_db_secret.sh
./k8s/scripts/create_mq_secret.sh
./k8s/scripts/create_api_secret.sh
# ... ensure you have the necessary API keys handy