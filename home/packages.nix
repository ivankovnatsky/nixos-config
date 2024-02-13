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
      ansible-core
      pip
      diagrams
    ]))

    _1password
    ansible-lint
    aws-sso-cli
    aws-sso-creds
    aws-vault
    awscli2
    azure-cli
    curlie
    dhall
    dhall-json
    difftastic
    doggo
    du-dust
    duf
    eks-node-viewer
    exiftool
    genpass
    ghq
    ghz
    git-ignore
    gitleaks
    glances
    gnumake
    gnused
    gnutar
    grpcui
    grpcurl
    home-manager
    htop
    iam-policy-json-to-terraform
    imagemagick
    istioctl
    jq
    jsonnet
    k9s
    kail
    krelay
    kube-score
    kubectl
    kubectl-images
    kubectl-ktop
    kubectx
    kubepug
    kubernetes-helm
    nixpkgs-fmt
    nixpkgs-master.aichat
    nixpkgs-review
    nixpkgs-unstable.husky # Commitlint dependency
    nixpkgs-unstable.k8sgpt
    nodePackages.webtorrent-cli
    p7zip
    packer
    pass2csv
    postgresql
    procps
    procs
    pstree
    rclone
    rnr
    rustup
    sd
    sops
    ssm-session-manager-plugin
    stc-cli
    syncthing
    tailscale
    tealdeer
    terraform
    tfk8s
    unrar
    unzip
    wget
    yamllint
    yq-go
    yt-dlp
    yubikey-manager
  ] ++ scriptPackages;
}
