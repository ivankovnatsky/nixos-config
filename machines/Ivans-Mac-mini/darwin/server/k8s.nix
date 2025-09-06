{ config, lib, pkgs, ... }:

{
  # Apply K8s secrets for build-time Kustomize replacements
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo >&2 "Applying K8s secrets for Kustomize replacements..."
    export KUBECONFIG="${config.users.users.ivan.home}/.kube/config"
    
    # Test cluster connectivity
    if ${pkgs.kubectl}/bin/kubectl cluster-info; then
      # Define list of git-crypt secret files to apply
      SECRET_FILES=(
        "machines/Ivans-Mac-mini/darwin/server/k8s/clusters/orbstack/openwebui/secret-openwebui-config.yaml"
        # Add more secret files here as needed
      )
      
      # Apply each secret file
      for SECRET_FILE in "''${SECRET_FILES[@]}"; do
        if [[ -f "$SECRET_FILE" ]]; then
          echo >&2 "Applying secret: $SECRET_FILE"
          ${pkgs.kubectl}/bin/kubectl apply -f "$SECRET_FILE"
        else
          echo >&2 "Warning: Secret file not found at $SECRET_FILE"
        fi
      done
    else
      echo >&2 "Orbstack cluster not accessible, skipping K8s secret application"
    fi
  '';
}
