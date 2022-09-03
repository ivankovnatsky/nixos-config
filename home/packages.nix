{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python310.withPackages (ps: with ps; [
      pip
      ansible-lint
      ansible
      yamllint
    ]))

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
    tealdeer
    terraform
    wget
    yamlfix
  ];
}
