#!/usr/bin/env bash

# Exit on error, but don't print commands
set -e

# Find all kube config files matching the pattern ~/.kube.*/config
get_kube_configs() {
    find "$HOME" -maxdepth 1 -type d -name ".kube.*" | while read -r dir; do
        config_file="$dir/config"
        if [[ -f "$config_file" ]]; then
            # Extract cluster name from directory (.kube.cluster_name -> cluster_name)
            cluster_name=${dir##*.}
            echo "$cluster_name"
        fi
    done | sort
}

# Check for fzf
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is not installed" >&2
    exit 1
fi

# Get configs
configs=$(get_kube_configs)

if [[ -z "$configs" ]]; then
    echo "Error: No Kubernetes configs found in ~/.kube.*/ directories" >&2
    exit 1
fi

# Use fzf to select a cluster
if selected_cluster=$(echo "$configs" | fzf --height 40% --border --prompt="Select Kubernetes Cluster > "); then
    selected_config="$HOME/.kube.$selected_cluster/config"
    # Export both KUBECONFIG and current context for better compatibility
    echo "export KUBECONFIG='$selected_config'"
fi
