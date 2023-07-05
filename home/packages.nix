{ lib, pkgs, ... }:

let
  scriptsDir = ./scripts;
  scriptFiles = builtins.readDir scriptsDir;

  processScript = scriptName:
    let
      scriptPath = "${scriptsDir}/${scriptName}";
      scriptContents = builtins.readFile scriptPath;
      scriptWithFixedShebang = builtins.replaceStrings [ "#!/usr/bin/env bash" ] [ "#!${pkgs.bash}/bin/bash" ] scriptContents;
    in
    pkgs.writeScriptBin (lib.removeSuffix ".sh" scriptName) scriptWithFixedShebang;

  filteredScriptNames = lib.filter (scriptName: lib.hasSuffix ".sh" scriptName) (builtins.attrNames scriptFiles);
  scriptPackages = builtins.map processScript filteredScriptNames;
in
{
  home.packages = with pkgs; [
    (python310.withPackages (ps: with ps; [
      pip
      ansible
      yamllint
    ]))

    awscli2
    ansible-lint
    _1password
    grpcui
    grpcurl
    ghz
    gnumake
    gnutar
    jsonnet
    gitleaks
    postgresql
    nixpkgs-unstable-pin.rustfmt
    clippy
    cargo
    exiftool
    go
    iam-policy-json-to-terraform
    p7zip
    kube-score
    unzip
    ssm-session-manager-plugin
    rclone
    gnused
    tfk8s
    nixpkgs-unstable-pin.istioctl
    aws-vault
    aws-sso-cli
    nixpkgs-unstable-pin.aws-sso-creds
    dhall
    dhall-json
    dogdns
    du-dust
    duf
    genpass
    ghq
    htop
    jq
    k9s
    packer
    procps
    pstree
    kubectl
    kubectl-images
    kail
    krelay
    kubectx
    kubernetes-helm
    nixpkgs-fmt
    nixpkgs-review
    rnr
    nixpkgs-unstable-pin.stc-cli
    nixpkgs-unstable-pin.kubectl-ktop
    sops
    syncthing
    tealdeer
    terraform
    wget
    yq-go
    nixpkgs-unstable-pin.k8sgpt
    nixpkgs-unstable-pin.eks-node-viewer
  ] ++ scriptPackages;
}
