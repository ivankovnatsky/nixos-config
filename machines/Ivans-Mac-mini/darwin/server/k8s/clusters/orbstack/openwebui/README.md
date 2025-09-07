# OpenWebUI Deployment

## Creating the Sealed Secret

After sealed-secrets controller is deployed, create the sealed secret with both the external domain and full host:

```console
# Create the sealed secret with both fields
kubectl create secret generic openwebui-config \
  --namespace=openwebui \
  --from-literal=external-domain="yourdomain.com" \
  --from-literal=host="openwebui.yourdomain.com" \
  --dry-run=client -o yaml | kubeseal \
  --controller-name=sealed-secrets-sealed-secrets \
  --controller-namespace=sealed-secrets \
  -o yaml > sealed-secret.yaml
```

The secret needs two fields:
- `external-domain`: The base domain (e.g., `yourdomain.com`)
- `host`: The full hostname for OpenWebUI (e.g., `openwebui.yourdomain.com`)

These values are used by Kustomize replacements to configure the ingress host.

## Applying the Sealed Secret

After creating/updating the sealed secret, apply it manually to ensure it's available for Kustomize:

```console
kubectl apply -f sealed-secret.yaml
```

This ensures the secret exists in the cluster before Flux attempts to use it for Kustomize replacements.