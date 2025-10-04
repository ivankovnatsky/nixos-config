# Kubernetes GitOps with Flux

This directory contains Kubernetes manifests managed by Flux for the Orbstack cluster.

## Structure

```
k8s/
├── clusters/
│   └── orbstack/           # Orbstack cluster manifests
│       ├── flux-system/    # Flux components
│       └── openwebui/      # OpenWebUI application
└── README.md               # This file
```

## Bootstrap Methods

### Option 1: Flux Operator Approach (Recommended)

Using the Flux Operator for managing Flux components, following the d2-fleet pattern.

#### Bootstrap Steps

1. Install Flux Operator using Helm:

```console
helm install flux-operator \
  oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

2. Apply the FluxInstance to configure sync from OCI artifacts:

```console
kubectl apply -f clusters/orbstack/flux-system/flux-instance.yaml
```

The Flux Operator will then pull the OCI artifacts from ghcr.io and apply all manifests.

## Secret Management

Secrets can be managed using one of these approaches:

### Git-crypt (for encrypted files in repo)

Encrypt secret manifests with git-crypt and apply them manually:

```console
# Decrypt and apply secret manifests
git-crypt unlock
kubectl apply -f clusters/orbstack/secrets/
```

### Vals (for external secret references)

Use vals to reference secrets from external sources (environment variables, files, etc.) and generate manifests dynamically.

## Managing Applications

### Adding New Applications

1. Create a new directory under `clusters/orbstack/`:

```console
mkdir clusters/orbstack/my-app
```

2. Add manifests:

   - `namespace.yaml` - Create namespace
   - `repository.yaml` - Helm repository (if using Helm)
   - `release.yaml` - HelmRelease or Deployment
   - `kustomization.yaml` - Kustomize configuration

3. Commit and push (if using GitOps) or apply manually:

```console
kubectl apply -k clusters/orbstack/my-app/
```

## Troubleshooting

Check Flux status:

```console
flux check
flux get all
flux logs --all-namespaces
```

Check Flux Operator (if using):

```console
kubectl get fluxinstance -A
kubectl describe fluxinstance flux -n flux-system
```

View reconciliation errors:

```console
kubectl get gitrepository -A
kubectl get kustomization -A
kubectl get helmrelease -A
```

## References

- [Flux Operator GitHub App Bootstrap](https://fluxcd.io/blog/2025/04/flux-operator-github-app-bootstrap/)
- [Flux Multi-tenancy Configuration](https://fluxcd.io/flux/installation/configuration/multitenancy/)
- [Flux Multi-tenancy Example](https://github.com/fluxcd/flux2-multi-tenancy)
- [D2 Fleet FluxInstance Example](https://github.com/controlplaneio-fluxcd/d2-fleet/blob/main/clusters/staging/flux-system/flux-instance.yaml)
- [Kyverno Helm Installation](https://kyverno.io/docs/installation/methods/#install-kyverno-using-helm)
- [Kyverno Flux Multi-tenant Policy](https://kyverno.io/policies/flux/generate-flux-multi-tenant-resources/generate-flux-multi-tenant-resources/)
- [OpenWebUI Helm Chart](https://github.com/open-webui/helm-charts)
