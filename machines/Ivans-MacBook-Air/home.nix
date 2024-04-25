{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  gitConfig = import ../../home/git.nix { inherit config pkgs; };
in
{
  imports = [
    ../../home/amethyst.nix
    ../../home/firefox-config.nix
    ../../home/mpv.nix
    ../../home/nixvim
    ../../home/scripts.nix
    ../../home/aichat.nix
    ../../home/tmux.nix
    ../../home/transmission.nix

    ../../modules
    ../../modules/secrets.nix
  ];
  variables = {
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

      rust-analyzer
      cargo
      rustc
    ];
    sessionVariables = {
      EDITOR = config.variables.editor;
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
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        update_check = false;
        style = "compact";
        inline_height = 25;
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
    git = {
      enable = true;
      userEmail = "75213+ivankovnatsky@users.noreply.github.com";
      userName = "Ivan Kovnatsky";
      signing = {
        signByDefault = true;
        key = "75213+ivankovnatsky@users.noreply.github.com";
      };
      ignores = [
        ".stignore"
      ];
      extraConfig = {
        core = {
          editor = config.variables.editor;
        };
        pull.rebase = false;
        push.default = "current";
      };
      aliases = gitConfig.programs.git.aliases;
    };
  };
}
