{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (wrapHelm kubernetes-helm { plugins = with pkgs.kubernetes-helmPlugins; [ helm-secrets ]; })
    argocd
    aws-sso-cli
    aws-sso-creds
    awscli2
    backup-home
    battery-toolkit # Local overlay
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
    nixpkgs-master.fluxcd
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
    krew
    kubecolor
    kubectl
    kubectl-images
    kubectl-view-secret
    kubectx
    kubepug
    kustomize
    maccy # Clipboard manager
    magic-wormhole
    mariadb
    mongosh
    mos # To use PC mouse with natural scrolling GUI
    mycli
    nixfmt-rfc-style
    nodePackages.aws-cdk
    nodejs
    opsy
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
    sesh
    smctemp
    sshpass
    ssm-session-manager-plugin
    stats # To show CPU, RAM, etc. usage in the menu bar
    terraformer
    terragrunt-atlantis-config
    vault
    watchman
    watchman-make
    wget
    yq
    zoxide
  ];
}
