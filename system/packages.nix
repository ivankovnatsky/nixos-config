{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    aws-vault
    bitwarden-cli
    delta
    dnsutils
    docker-compose
    dogdns
    du-dust
    duf
    envsubst
    exa
    fd
    file
    genpass
    git
    gitAndTools.pre-commit
    git-crypt
    go
    htop
    jsonnet
    jq
    k9s
    kubectl
    kubectx
    kubernetes-helm
    lastpass-cli
    mdl
    mtr
    neovim
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    pinentry
    postgresql
    python38
    python38Packages.grip
    python38Packages.pylint
    rbw
    rclone
    ripgrep
    shellcheck
    syncthing
    tealdeer
    terraform
    terraformer
    tflint
    unzip
    wget
    whois
    yamllint
    youtube-dl
  ];
}
