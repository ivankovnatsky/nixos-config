{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
in
{
  imports = [
    ../../home/amethyst.nix
    ../../home/firefox-config.nix
    ../../home/mpv.nix
    ../../home/git.nix
    ../../home/nixvim
    ../../home/scripts.nix
    ../../home/aichat.nix
    ../../home/tmux.nix
    ../../home/transmission.nix

    ../../modules/flags
    ../../modules/secrets
  ];
  flags = {
    purpose = "home";
    editor = "nvim";
    darkMode = false;
  };
  home = {
    packages = with pkgs; [
      home-manager
      zsh-forgit
      rclone
      aria2
      nodePackages.webtorrent-cli
      exiftool
      syncthing
      yt-dlp
      bat
      ripgrep
      delta
      nixpkgs-fmt
      magic-wormhole-rs
      typst
      typstfmt
      du-dust
      genpass

      nixpkgs-master.ollama

      rust-analyzer
      cargo
      rustc
    ];
    sessionVariables = {
      EDITOR = config.flags.editor;
    };
  };
  programs = {
    nixvim = {
      plugins = {
        lsp = {
          servers = {
            typst-lsp.enable = true;
            rust-analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
            };
          };
        };
      };
    };
    z-lua = {
      enable = true;
      enableZshIntegration = true;
    };
    atuin = {
      package = pkgs.nixpkgs-master.atuin;
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
        style = "compact";
        inline_height = 25;
        # history_filter = [ ];
      };
    };
    zsh = {
      enable = true;
      enableAutosuggestions = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      autocd = true;
      # autosuggestion.enable = true;
      shellAliases = {
        top = if isDarwin then "top -o cpu" else "top";
        g = "git";
        rm-image-meta = "exiftool -all= -overwrite_original";
        show-image-meta = "exiftool";
      };
      sessionVariables = { _ZL_HYPHEN = 1; };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
