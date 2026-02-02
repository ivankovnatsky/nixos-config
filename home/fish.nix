{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  syncthingHomeDir =
    if isDarwin then "~/Library/Application\\ Support/Syncthing" else "~/.config/syncthing";

  commonShellAliases = {
    # TODO: add function nix-prefetch-url $url | xargs nix hash to-sri --type sha256
    g = "${pkgs.git}/bin/git";
    erd = "${pkgs.erdtree}/bin/erd --color auto --human -L 1 --layout inverted --icons --long --hidden";
    # Let's not use GNU Coreutils mkdir for now.
    mkdir = "mkdir -p";
    less = "less -RS";
    syncthing = "${pkgs.syncthing}/bin/syncthing serve --no-browser";
    stc = "${pkgs.stc-cli}/bin/stc -homedir ${syncthingHomeDir}";
  };

  shellAliases =
    if config.flags.purpose == "home" then
      commonShellAliases
      // {
        rclone = "${pkgs.rclone}/bin/rclone -P";
        wl-copy = lib.mkIf isLinux "${pkgs.wl-clipboard}/bin/wl-copy -n";
      }
    else
      commonShellAliases
      // {
        # We tenv version manager so pkgs interpolation is not needed.
        tf = "tofu";
        tg = "terragrunt";
        k = "${pkgs.kubectl}/bin/kubectl";
        argocd = "${pkgs.argocd}/bin/argocd --grpc-web";
      };

in
{
  home.packages = with pkgs; [
    # Install grc only when config.flags.enableFishShell = true
    (lib.mkIf config.flags.enableFishShell grc)
  ];

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/fish.nix
  programs.fish = {
    enable = config.flags.enableFishShell;
    shellInit = ''
      # Add Nix paths early to ensure tools are available before plugins load
      # Order matters: last prepend ends up first in PATH
      if test -d /etc/profiles/per-user/$USER/bin
          fish_add_path --prepend /etc/profiles/per-user/$USER/bin
      end
      if test -d /run/current-system/sw/bin
          fish_add_path --prepend /run/current-system/sw/bin
      end
      # Security wrappers (setuid sudo, etc.) must come first in PATH
      if test -d /run/wrappers/bin
          fish_add_path --prepend /run/wrappers/bin
      end

      set -U fish_term24bit 1
    '';

    interactiveShellInit = ''
      set fish_greeting # Disable greeting

      # Disable focus reporting mode to prevent [I and [O escape sequences
      # https://github.com/anthropics/claude-code/issues/10375
      printf '\e[?1004l'

      # https://fishshell.com/docs/current/interactive.html#vi-mode-commands
      fish_vi_key_bindings

      # z.lua -- this is needed for words with hyphens to autocomplete
      set -x _ZL_HYPHEN 1

      if test -d $HOME/bin
          set -gx PATH $PATH $HOME/bin
      end

      if test -d $GOPATH/bin
          set -gx PATH $PATH $GOPATH/bin
      end

      if test -d $HOME/.npm/bin
          set -gx PATH $PATH $HOME/.npm/bin
      end

      if test -d $HOME/.bun/bin
          set -gx PATH $PATH $HOME/.bun/bin
      end

      if test -d $HOME/.local/bin
          set -gx PATH $PATH $HOME/.local/bin
      end

      # Git completions; FIXME: remove this once landed in upstream in
      # fish-shell and later when package updated in nixpkgs.
      # https://github.com/fish-shell/fish-shell/pull/10133
      complete -f -c git -n '__fish_git_using_command branch' -l contains -d 'List branches that contain the specified commit' -xa '(__fish_git_commits)'
      complete -f -c git -n '__fish_git_using_command branch' -l no-contains -d 'List branches that don\'t contain the specified commit' -xa '(__fish_git_commits)'

      # https://github.com/remigourdon/dotfiles/commit/733971c51c7dd1050b786c0fdc7ce04bd2661197
      complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'

      # Add aichat completions for ai
      if command -v aichat >/dev/null
          complete -c ai -w aichat
      end

      # forgit completions - only show subcommands when no subcommand entered yet
      complete -c git-forgit -n "__fish_is_first_arg" -a "add attributes blame branch_delete checkout_branch checkout_commit checkout_file checkout_tag cherry_pick cherry_pick_from_branch clean diff fixup squash reword ignore log reflog rebase reset_head revert_commit show stash_show stash_push"
      complete -c git-forgit -n "__fish_is_first_arg" -f

      # Source ~/.env.fish if exists
      # if test -f $HOME/.env.fish
      #     source $HOME/.env.fish
      # end

    '';
    plugins =
      with pkgs.fishPlugins;
      [
        { inherit (fzf-fish) name src; }
        { inherit (grc) name src; }
        # { inherit (plugin-git) name src; }  # Disabled - using carapace for git completions
        { inherit (forgit) name src; }
        { inherit (autopair) name src; }
        { inherit (puffer) name src; }
        { inherit (colored-man-pages) name src; }
        { inherit (git-abbr) name src; }
        { inherit (fish-bd) name src; }
        { inherit (done) name src; }
        { inherit (bass) name src; }
      ]
      ++ lib.optionals isDarwin (
        with pkgs.fishPlugins;
        [
          { inherit (macos) name src; }
        ]
      );

    inherit shellAliases;
  };
}

# fish: upgraded to version 4.3:
# * Color variables are no longer set in universal scope by default.
#   Migrated them to global variables set in ~/.config/fish/conf.d/fish_frozen_theme.fish
#   To restore syntax highlighting in other fish sessions, please restart them.
# * The fish_key_bindings variable is no longer set in universal scope by default.
#   Migrated it to a global variable set in  ~/.config/fish/conf.d/fish_frozen_key_bindings.fish
# See also the release notes (type `help relnotes`).
