# OpenWebUI Deployment

## Creating the Sealed Secret

After sealed-secrets controller is deployed, create the sealed secret for the external domain:

```console
# Create the sealed secret
echo -n "your-actual-domain.com" | \
kubectl create secret generic openwebui-config \
  --namespace=openwebui \
  --dry-run=client \
  --from-file=external-domain=/dev/stdin \
  -o yaml | kubeseal --controller-name=sealed-secrets-sealed-secrets --controller-namespace=sealed-secrets -o yaml > sealed-secret.yaml
```