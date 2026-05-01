{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python313.withPackages (
      ps: with ps; [
        grip
        # markitdown — pulls python3-speechrecognition → openai-whisper, whose
        # check phase fails on aarch64-darwin ("Failed to load audio" via
        # ffmpeg in the sandbox). Re-enable once upstream nixpkgs lands a fix.
        # markitdown
        (jira.overridePythonAttrs (old: {
          propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ old.optional-dependencies.cli;
        }))
      ]
    ))
    (wrapHelm kubernetes-helm { plugins = with pkgs.kubernetes-helmPlugins; [ helm-secrets ]; })
    # jsonnet # ruby3.3-nokogiri build fails: fatal error: 'nokogiri_gumbo.h' file not found
    # kcat # avro-c++ build fails with fmt 11.2.0: error: no matching member function for call to 'format' in fmt::formatter<avro::Type>
    apacheKafka
    argocd
    aws-account-open
    aws-profile
    aws-sso-cli
    aws-sso-creds
    awscli2
    claude-code-logs
    cloudflared
    confluence
    confluent-cli
    coreutils
    crane
    create-pr
    curlie
    cxctl
    defaultbrowser
    devbox
    devcontainer
    docker-client
    docker-compose
    docker-credential-helpers
    dockutil # macOS related CLI
    doggo
    eks-node-viewer
    flarectl
    ggh
    gh-prs-merged-today
    ghorg-sync
    git-worktree-init
    glow
    google-cloud-sdk
    grpcui
    grpcurl
    gum
    hadolint
    hclfmt
    iam-policy-json-to-terraform
    infra
    infracost
    jcli
    jira-custom
    k-nodes-by-label
    k-number-of-replicas
    k8s-context
    k8sgpt
    kail
    kdash
    kitty-copy
    kn
    krew
    kubecolor
    kubectl
    kubectl-ai
    kubectl-images
    kubectl-view-secret
    kubectx
    kubepug
    kustomize
    ldns
    lsd
    mariadb
    mongosh
    mycli
    nh # https://github.com/nix-community/nh
    nixpkgs-darwin-master.cursor-cli
    nixpkgs-darwin-master.fluxcd
    nixpkgs-darwin-master.jira-cli-go
    nixpkgs-darwin-master-opencode.opencode
    nixpkgs-darwin-master.poetry
    aws-cdk-cli
    opentofu
    opsy
    oras
    orphaned-snapshots
    pblock
    pnpm
    popeye
    postgresql
    pre-commit
    pyenv-nix-install
    q
    rabbitmq-server # Needed for the CLI
    rabbitmqadmin-ng # Overlay
    redis
    sesh
    sesh-connect
    skopeo
    slack-cli-go
    sshpass
    ssm-forward
    ssm-session-manager-plugin
    temporal
    temporal-cli
    terraformer
    terragrunt-atlantis-config
    treefmt
    uv
    vals
    vault
    vault-auth
    vkv
    yazi
    yq
    zscaler-kill
  ];
}
