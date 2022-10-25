{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (python310.withPackages (ps: with ps; [
      pip
      ansible-lint
      ansible
      yamllint
    ]))

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
    nixpkgs-fmt
    nixpkgs-review
    sops
    tealdeer
    terraform
    wget
    yamlfix
  ];
}
