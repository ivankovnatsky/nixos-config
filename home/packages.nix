{ pkgs, ... }:

{
  home.packages = with pkgs; [
    _1password
    awscli2
    aws-vault
    bemenu
    delta
    dhall
    dhall-json
    dogdns
    du-dust
    duf
    envsubst
    exiftool
    file
    genpass
    gitleaks
    gnumake
    go
    htop
    imagemagick
    ipcalc
    jq
    jsonnet
    k9s
    keepassxc
    killall
    kubecolor
    kubectl
    kubectl-tree
    kubectx
    kubernetes-helm
    kubetail
    mtr
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    nmap
    nodePackages.peerflix
    openssl
    p7zip
    postgresql
    procs
    python38
    rclone
    ripgrep
    sops
    ssm-session-manager-plugin
    syncthing
    tealdeer
    terraform
    terraformer
    tflint
    unzip
    viddy
    wget
    whois
    yamllint
    youtube-dl
    zip
  ];
}
