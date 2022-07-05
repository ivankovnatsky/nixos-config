{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
