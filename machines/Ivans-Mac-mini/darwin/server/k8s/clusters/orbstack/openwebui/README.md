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