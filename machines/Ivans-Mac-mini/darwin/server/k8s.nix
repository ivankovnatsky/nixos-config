{ config, lib, pkgs, ... }:

let
  repoPath = "/Volumes/Storage/Data/Sources/github.com/ivankovnatsky/nixos-config";
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo >&2 "Applying K8s manifests..."
    export KUBECONFIG="${config.users.users.ivan.home}/.kube/config"

    cd "${repoPath}"
    # Define list of manifests to apply
    FILES=(
      "machines/Ivans-Mac-mini/darwin/server/k8s/clusters/orbstack/openwebui/ingress.yaml"
    )

    for FILE in "''${FILES[@]}"; do
      echo >&2 "Applying secret: $FILE"
      ${pkgs.kubectl}/bin/kubectl apply -f "$FILE"
    done
  '';
}
