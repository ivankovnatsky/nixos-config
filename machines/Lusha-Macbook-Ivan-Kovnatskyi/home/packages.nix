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

    # ```console
    # node:internal/modules/cjs/loader:1215
    # throw err;
    # ^

    # Error: Cannot find module '/nix/store/g6d2pfbvbgmmnalp4rss1qb0i7y7zcfy-claude-code-1.0.62/lib/node_modules/@anthropic-ai/claude-code/cli.js'
    #     at Module._resolveFilename (node:internal/modules/cjs/loader:1212:15)
    #     at Module._load (node:internal/modules/cjs/loader:1043:27)
    #     at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:164:12)
    #     at node:internal/main/run_main_module:28:49 {
    #   code: 'MODULE_NOT_FOUND',
    #   requireStack: []
    # }

    # Node.js v20.19.4
    # ```
    # nixpkgs-master.claude-code #

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
