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
      ansible-core
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
    rustup
    exiftool
    go
    iam-policy-json-to-terraform
    imagemagick
    p7zip
    kube-score
    unzip
    ssm-session-manager-plugin
    rclone
    gnused
    tfk8s
    nixpkgs-unstable.istioctl
    aws-vault
    aws-sso-cli
    aws-sso-creds
    dhall
    dhall-json
    doggo
    du-dust
    duf
    difftastic
    genpass
    ghq
    htop
    glances
    jq
    k9s
    packer
    procs
    procps
    pass2csv
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
    stc-cli
    kubectl-ktop
    sd
    sops
    syncthing
    tealdeer
    terraform
    wget
    yq-go
    nixpkgs-unstable.k8sgpt
    eks-node-viewer
    yubikey-manager
    yamllint
    home-manager
    nodePackages.webtorrent-cli

    # Commitlint dependency
    nixpkgs-unstable.husky

  ] ++ scriptPackages;
}
