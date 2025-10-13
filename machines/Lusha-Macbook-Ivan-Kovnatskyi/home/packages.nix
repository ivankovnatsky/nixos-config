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
    argocd
    aws-sso-cli
    aws-sso-creds
    awscli2
    backup-home
    cargo
    cloudflared
    confluent-cli
    coreutils
    crane
    defaultbrowser
    delta
    devbox
    devcontainer
    docker-client
    docker-compose
    docker-credential-helpers
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
    gofumpt
    golangci-lint
    google-cloud-sdk
    gum
    hadolint
    hclfmt
    home-manager
    iam-policy-json-to-terraform
    jcli
    imagemagick
    infra
    infracost
    jq
    jsonnet
    k8sgpt
    kail
    # kcat # avro-c++ build fails with fmt 11.2.0: error: no matching member function for call to 'format' in fmt::formatter<avro::Type>
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
    nixpkgs-master.cursor-cli
    nixpkgs-master.fluxcd
    nixpkgs-master.jira-cli-go
    nodePackages.aws-cdk
    nodePackages.prettier
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
    shellcheck
    shfmt
    skopeo
    slack-cli-go
    smctemp
    sshpass
    ssm-session-manager-plugin
    stylua
    terraformer
    terragrunt-atlantis-config
    treefmt
    username # Installed as flake
    uv
    vault
    watchman
    watchman-make
    wget
    yq
    zoxide
  ];
}
