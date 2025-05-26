{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    defaultbrowser
    delta
    devbox
    docker-client
    docker-compose
    dockutil # macOS related CLI
    duf
    dust
    eks-node-viewer
    exiftool
    genpass
    ggh
    ghorg
    gitleaks
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
    keycastr # macOS: Keystroke visualizer
    krew
    kubecolor
    kubectl
    kubectl-ai
    kubectl-images
    kubectl-view-secret
    kubectx
    kubepug
    kustomize
    maccy # Clipboard manager
    magic-wormhole
    mariadb
    mongosh
    mos # macOS: Use PC mode for mouse, instead of natural scrolling
    mycli
    nh # https://github.com/nix-community/nh
    nixfmt-rfc-style
    nixpkgs-master.fluxcd
    nodePackages.aws-cdk
    nodejs
    opsy
    oras
    parallel
    pigz
    poetry
    popeye
    postgresql
    pre-commit
    pv
    pyenv-nix-install
    rabbitmq-server # Needed for the CLI
    rabbitmqadmin-ng # Overlay
    rclone
    rectangle # Window manager
    rust-analyzer
    rustc
    sesh
    skopeo
    smctemp
    sshpass
    ssm-session-manager-plugin
    stats # macOS: System stats; Configure `Check for update` to `Never`.
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
