{ pkgs, ... }:

let
  bwget = pkgs.writeScriptBin "bwget" ''
    ${toString(builtins.readFile ../files/bwget.sh)}
  '';

in
{
  home.packages = with pkgs; [
    element-desktop
    asciinema
    _1password
    awscli2
    aws-vault
    bemenu
    bloomrpc
    bwget
    dbeaver
    delta
    dhall
    dhall-json
    discord
    dogdns
    du-dust
    duf
    envsubst
    exiftool
    file
    genpass
    ghq
    gitleaks
    gnumake
    go
    google-cloud-sdk
    grpcui
    grpcurl
    hcloud
    htop
    imagemagick
    ipcalc
    jami-client-qt
    jami-daemon
    jetbrains.datagrip
    jless
    jq
    jsonnet
    k9s
    keepassxc
    killall
    krelay
    kubecolor
    kubectl
    kubectl-tree
    kubectx
    kubernetes-helm
    kube-score
    kubetail
    mtr
    nixpkgs-fmt
    nixpkgs-review
    nix-tree
    nmap
    nodePackages.peerflix
    openssl
    p7zip
    podman-compose
    postgresql
    procs
    protonvpn-cli
    python38
    python38Packages.j2cli
    rclone
    ripgrep
    signal-desktop
    slack
    sops
    ssm-session-manager-plugin
    syncthing
    tdesktop
    tealdeer
    terraform
    terraformer
    tflint
    unzip
    viddy
    wget
    whois
    yamlfix
    yamllint
    youtube-dl
    zip
    zoom-us
  ];
}
