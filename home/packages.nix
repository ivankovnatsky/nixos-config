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
      ansible-lint
      ansible
      yamllint
    ]))

    _1password
    grpcui
    grpcurl
    ghz
    gnumake
    gnutar
    yq
    jsonnet
    gitleaks
    postgresql
    rustfmt
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
    nixpkgs-unstable.istioctl
    aws-vault
    aws-sso-cli
    aws-sso-creds
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
    procs
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
    sops
    tealdeer
    terraform
    wget
    yamlfix
  ] ++ scriptPackages;
}
