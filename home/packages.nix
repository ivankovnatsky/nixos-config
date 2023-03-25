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
