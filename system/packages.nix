{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli2
    awscurl
    aws-vault
    dnsutils
    docker-compose
    dogdns
    du-dust
    duf
    exa
    fd
    file
    genpass
    git
    gitAndTools.pre-commit
    git-crypt
    git-ignore
    go
    htop
    jq
    k9s
    kubectl
    kubectx
    kubernetes-helm
    lastpass-cli
    mdl
    neovim
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    ntp
    python38
    python38Packages.grip
    python38Packages.pylint
    postgresql
    rclone
    ripgrep
    shellcheck
    tflint
    tealdeer
    terraform
    terragrunt
    unzip
    rbw
    pinentry
    wget
    youtube-dl
  ];
}
