{ pkgs, ... }:

{
  home.packages = with pkgs; [
    delta
    gnused
    tfk8s
    istioctl
    _1password
    awscli2
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
    kubectl
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
