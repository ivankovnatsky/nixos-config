{ pkgs, ... }:

{
  home.packages = with pkgs; [
    exiftool
    go
    iam-policy-json-to-terraform
    p7zip
    kube-score
    unzip
    telepresence2
    ssm-session-manager-plugin
    rclone
    delta
    gnused
    tfk8s
    istioctl
    aws-vault
    dhall
    dhall-json
    dogdns
    du-dust
    genpass
    ghq
    htop
    jq
    k9s
    procs
    krelay
    kubectx
    kubernetes-helm
    kubetail
    nixpkgs-fmt
    nixpkgs-review
    sops
    syncthing
    tealdeer
    terraform
    wget
    yamlfix
    yamllint
  ];
}
