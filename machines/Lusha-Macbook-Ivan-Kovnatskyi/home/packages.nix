{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
        (jira.overridePythonAttrs (old: {
          propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ old.optional-dependencies.cli;
        }))
        ruff
      ]
    ))
    (wrapHelm kubernetes-helm { plugins = with pkgs.kubernetes-helmPlugins; [ helm-secrets ]; })
    # jsonnet # ruby3.3-nokogiri build fails: fatal error: 'nokogiri_gumbo.h' file not found
    # kcat # avro-c++ build fails with fmt 11.2.0: error: no matching member function for call to 'format' in fmt::formatter<avro::Type>
    argocd
    aws-sso-cli
    aws-sso-creds
    awscli2
    backup-home
    bat
    cargo
    cloudflared
    confluence
    confluent-cli
    coreutils
    crane
    curlie
    defaultbrowser
    delta
    devbox
    devcontainer
    docker-client
    docker-compose
    docker-credential-helpers
    dockutil # macOS related CLI
    doggo
    duf
    dust
    eks-node-viewer
    erdtree
    exiftool
    genpass
    ggh
    gh-pr
    ghorg
    git-message
    git-pull-all
    gitleaks
    glow
    go-grip
    gofumpt
    golangci-lint
    google-cloud-sdk
    gum
    hadolint
    hclfmt
    home-manager
    iam-policy-json-to-terraform
    imagemagick
    infra
    infracost
    jcli
    jq
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
    lsd
    magic-wormhole
    mariadb
    mkcd
    mkpasswd
    mongosh
    mycli
    nh # https://github.com/nix-community/nh
    nixfmt-rfc-style
    nixpkgs-darwin-master.cursor-cli
    nixpkgs-darwin-master.fluxcd
    nixpkgs-darwin-master.jira-cli-go
    nodejs
    nodePackages.aws-cdk
    nodePackages.prettier
    open-gh-notifications-py
    opentofu
    opsy
    oras
    parallel
    perplexity
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
    redis
    rust-analyzer
    rustc
    sesh
    dns
    jira-custom
    shellcheck
    shfmt
    skopeo
    slack-cli-go
    smctemp
    ssh-to-age
    sshpass
    ssm-session-manager-plugin
    stylua
    settings
    syncthing-mgmt
    terraformer
    terragrunt-atlantis-config
    tmux-spawn
    tree
    treefmt
    username # Installed as flake
    uv
    vault
    watchman
    watchman-make
    watchman-rebuild
    wget
    yq
    zoxide
  ];
}
