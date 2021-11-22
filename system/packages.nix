{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    aws-vault
    delta
    bitwarden-cli
    broot
    dnsutils
    docker-compose
    dogdns
    du-dust
    duf
    envsubst
    exa
    exiftool
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
    kubecolor
    kubectl
    kubectx
    kubernetes-helm
    kubetail
    lastpass-cli
    mdl
    mtr
    neovim
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    pinentry
    postgresql
    procs
    python38
    python38Packages.grip
    python38Packages.pylint
    rbw
    rclone
    ripgrep
    shellcheck
    ssm-session-manager-plugin
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

    rnix-lsp
    nodePackages.pyright
    nodePackages.bash-language-server
    terraform-ls
  ];
}
