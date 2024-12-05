#!/usr/bin/env bash

# Under fish shell:
# ```console
# eval (switch-k8s-context.sh)             # interactive mode
# eval (switch-k8s-context.sh cluster-name) # direct mode
# ```

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

# Get the cluster name from the argument, if provided
cluster_name_arg="$1"

# Get configs
configs=$(get_kube_configs)

if [[ -z "$configs" ]]; then
    echo "Error: No Kubernetes configs found in ~/.kube.*/ directories" >&2
    exit 1
fi

# Check if a cluster name was provided as an argument
if [[ -n "$cluster_name_arg" ]]; then
    if echo "$configs" | grep -q "^$cluster_name_arg$"; then
        selected_cluster="$cluster_name_arg"
    else
        echo "Error: Cluster '$cluster_name_arg' not found" >&2
        exit 1
    fi
else
    # Use fzf to select a cluster
    selected_cluster=$(echo "$configs" | fzf --height 40% --border --prompt="Select Kubernetes Cluster > ")
fi

# Export the selected cluster config if a cluster was selected
if [[ -n "$selected_cluster" ]]; then
    selected_config="$HOME/.kube.$selected_cluster/config"
    echo "export KUBECONFIG='$selected_config'"
fi
