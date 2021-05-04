{ pkgs, ... }:

{

  # nixpkgs.overlays = [
  #   (self: super: {
  #     terraform_0_14 = super.terraform_0_14.overrideAttrs (old: rec {
  #       name = "terraform-${version}";
  #       version = "0.14.4";
  #       src = super.fetchFromGitHub {
  #         owner = "hashicorp";
  #         repo = "terraform";
  #         rev = "v${version}";
  #         sha256 = "0kjbx1gshp1lvhnjfigfzza0sbl3m6d9qb3in7q5vc6kdkiplb66";
  #       };
  #     });
  #   })
  # ];

  home.packages = with pkgs; [
    acpi
    arandr
    awless
    awscli2
    aws-iam-authenticator
    aws-vault
    binutils-unwrapped
    bitwarden-cli
    brightnessctl
    dmidecode
    dnsutils
    docker-compose
    dogdns
    du-dust
    duf
    exa
    exiftool
    fd
    file
    fwts
    gnome3.eog
    genpass
    geteltorito
    gettext
    gimp
    gitAndTools.pre-commit
    glances
    gnome3.adwaita-icon-theme
    gnome3.nautilus
    gnumake
    hadolint
    htop
    hwinfo
    i2c-tools
    imagemagick
    irssi
    iw
    jq
    jsonnet
    k9s
    killall
    kubectl
    kubectx
    kubernetes-helm
    kubetail
    lm_sensors
    lshw
    maim
    mdl
    nixfmt
    nixpkgs-review
    nix-tree
    openssl
    pass
    pavucontrol
    pciutils
    ranger
    rclone
    ripgrep
    rubber
    shellcheck
    signal-desktop
    strace
    sysstat
    tcpdump
    terragrunt
    tflint
    tfsec
    traceroute
    unzip
    usbutils
    viber
    wget
    xclip
    xorg.xev
    youtube-dl
    zathura
    zip

    (texlive.combine {
      inherit (texlive) scheme-small xetex collection-fontsrecommended moderncv;
    })

    (python38.withPackages (ps: with ps; [ grip rich ]))

    (terraform_0_14.withPlugins (p: [
      p.archive
      p.aws
      p.external
      p.gitlab
      p.grafana
      p.helm
      p.kubernetes
      p.local
      p.null
      p.random
      p.template
      p.tls
    ]))

  ];
}
