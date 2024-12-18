#!/usr/bin/env bash

# Script to list Kubernetes nodes by pod label
# Usage: ./k-list-nodes-by-app-label.sh <label-selector>
# Example: ./k-list-nodes-by-app-label.sh app.kubernetes.io/instance=lusha-accounts

if [ $# -eq 0 ]; then
    echo "Error: Label selector is required"
    echo "Usage: $0 <label-selector>"
    echo "Example: $0 app.kubernetes.io/instance=lusha-accounts"
    exit 1
fi

LABEL_SELECTOR="$1"

echo "Fetching nodes for pods with label: $LABEL_SELECTOR"
echo "NODE NAME                                     INSTANCE TYPE"
echo "-------------------------------------------------------------------------"

kubectl get pods -l "$LABEL_SELECTOR" -o custom-columns=NODE:spec.nodeName --no-headers | \
    sort -u | \
    xargs -I {} -P 20 kubectl get nodes {} --no-headers \
    -o custom-columns=NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.'node\.kubernetes\.io/instance-type'
