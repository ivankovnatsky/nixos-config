{ pkgs, ... }:
{
    home.packages = with pkgs; [
      # username # Installed as flake  # FIXME: correct hash256
      (python312.withPackages (ps: with ps; [ grip ]))
      aria2
      bat
      battery-toolkit # Local overlay
      cargo
      coconutbattery # macOS: Battery
      delta
      du-dust
      duf
      fish-ai # Local overlay
      fzf
      genpass
      home-manager
      jq
      ks
      magic-wormhole
      mos # macOS: System stats
      nixfmt-rfc-style
      nodejs
      parallel
      pigz
      rclone
      rectangle # macOS: Window manager
      ripgrep
      rust-analyzer
      rustc
      stats # macOS: System stats
      syncthing
      typst
      typstfmt
      watchman
      watchman-make
      wget
      yt-dlp
      zsh-forgit
    ];
}
