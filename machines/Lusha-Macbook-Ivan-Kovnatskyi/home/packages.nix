{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python313.withPackages (ps: with ps; [ grip ]))
    (wrapHelm kubernetes-helm { plugins = with pkgs.kubernetes-helmPlugins; [ helm-secrets ]; })
    argocd
    aws-sso-cli
    aws-sso-creds
    awscli2
    backup-home
    btop
    cargo
    cloudflared
    coreutils
    crane
    defaultbrowser
    delta
    devbox
    docker-client
    docker-compose
    dockutil # macOS related CLI
    duf
    dust
    eks-node-viewer
    erdtree
    exiftool
    genpass
    ggh
    ghorg
    gitleaks
    go-grip
    gum
    hadolint
    hclfmt
    home-manager
    iam-policy-json-to-terraform
    imagemagick
    infra
    infracost
    jq
    jsonnet
    k8sgpt
    kail
    kdash
    krew
    kubecolor
    kubectl
    kubectl-ai
    kubectl-images
    kubectl-view-secret
    kubectx
    kubepug
    kustomize
    magic-wormhole
    mariadb
    mkpasswd
    mongosh
    mycli
    nh # https://github.com/nix-community/nh
    nixfmt-rfc-style
    nixpkgs-master.fluxcd
    nodePackages.aws-cdk
    nodePackages.rimraf
    nodejs
    opsy
    oras
    parallel
    pigz
    pnpm
    poetry
    popeye
    postgresql
    pre-commit
    pv
    pyenv-nix-install
    rabbitmq-server # Needed for the CLI
    rabbitmqadmin-ng # Overlay
    rclone
    rust-analyzer
    rustc
    sesh
    skopeo
    smctemp
    sshpass
    ssm-session-manager-plugin
    terraformer
    terragrunt-atlantis-config
    username # Installed as flake
    vault
    watchman
    watchman-make
    wget
    yq
    zoxide
  ];
}
