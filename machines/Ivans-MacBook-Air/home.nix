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
    ../../home/tmux.nix

    ../../modules
  ];
  variables = {
    purpose = "home";
    editor = "vim";
    darkMode = false;
  };
  home = {
    packages = with pkgs; [
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
    ];
    sessionVariables = {
      EDITOR = config.variables.editor;
    };
    file = {
      ".manual/config".text = ''
        # Do not enter user password too often
        bash -c 'cat << EOF > /private/etc/sudoers.d/ivan
        Defaults:ivan timestamp_timeout=240
        EOF'
      '';
      ".cache/vim/undo/.keep".text = "";
    };
  };
  programs = {
    z-lua = {
      enable = true;
      enableZshIntegration = true;
    };
    vim = {
      enable = true;
      # https://stackoverflow.com/a/76594191
      packageConfigurable = pkgs.vim-darwin;
      defaultEditor = if config.variables.editor == "vim" then true else false;
      plugins = with pkgs.vimPlugins; [
        fzf-vim
        copilot-vim
        vim-lastplace
        vim-nix
        vim-fugitive
        neoformat
        vim-commentary
        vim-sensible
        vim-sleuth
        vim-strip-trailing-whitespace
        vim-surround
      ];
      settings = {
        background = if config.variables.darkMode then "dark" else "light";
      };
      extraConfig =
        builtins.readFile (../../home/vim/vimrc) +
        builtins.readFile (../../home/vim/common-plugins.vim) +
        ''
          " I want to run :Lex when I'm not opening a file with vim
          " Also I want Lex to be resized to 20
          autocmd VimEnter * if argc() == 0 | Lex 20 | endif

          " Hide netrw banner
          let g:netrw_banner = 0

          " Set cursor shape depending on mode
          " https://vim.fandom.com/wiki/Change_cursor_shape_in_different_modes#For_tmux_running_in_iTerm2_on_OS_X
          let &t_SI.="\e[6 q" "SI = INSERT mode
          let &t_SR.="\e[4 q" "SR = REPLACE mode
          let &t_EI.="\e[2 q" "EI = NORMAL mode (ELSE)

          " Cursor settings:
          " 1 -> blinking block
          " 2 -> solid block
          " 3 -> blinking underscore
          " 4 -> solid underscore
          " 5 -> blinking vertical bar
          " 6 -> solid vertical bar

          " https://stackoverflow.com/a/58042714
          " Rest option are configured by vim-sensible
          set ttyfast
        '';
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
