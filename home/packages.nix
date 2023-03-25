{ pkgs, ... }:

let
  passDisableMaccy = pkgs.writeScriptBin "pass-safe" ''
    #!/usr/bin/env ${pkgs.bash}/bin/bash

    defaults write org.p0deje.Maccy ignoreEvents true
    ${pkgs.pass}/bin/pass $1 -c
    sleep 0.5
    defaults write org.p0deje.Maccy ignoreEvents false
  '';

in
{
  home.packages = with pkgs; [
    (python310.withPackages (ps: with ps; [
      pip
      ansible-lint
      ansible
      yamllint
    ]))

    passDisableMaccy

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
  ];
}
