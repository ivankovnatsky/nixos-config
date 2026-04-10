{
  config,
  lib,
  pkgs,
  ...
}:

let
  shellAliases = import ./aliases.nix { inherit config lib pkgs; };

in
{
  programs.bash = {
    enable = true;
    inherit shellAliases;
    historySize = 0;
    historyFile = "/dev/null";
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    sessionVariables = {
      HISTFILE = "/dev/null";
      HISTSIZE = "0";
      HISTFILESIZE = "0";
    };
    # Disable shell options that don't work in bash 3.2 (macOS default)
    shellOptions = [ ];
    # Don't enable bash completion by default (causes issues with bash 3.2)
    enableCompletion = false;
    initExtra = ''
      export GPG_TTY=$(tty)

      # Ensure Nix paths are available (especially for non-interactive agent shells)
      if [[ -d /etc/profiles/per-user/$USER/bin ]]; then
        export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
      fi
      export PATH="/run/current-system/sw/bin:$PATH"

      if [[ -d $HOME/bin ]]; then
        export PATH=$PATH:$HOME/bin
      fi

      if [[ -n "$GOPATH" && -d "$GOPATH/bin" ]]; then
        export PATH=$PATH:$GOPATH/bin
      fi

      if [[ -d ${config.flags.homeWorkPath}/.npm/bin ]]; then
        export PATH=$PATH:${config.flags.homeWorkPath}/.npm/bin
      fi

      if [[ -d ${config.flags.homeWorkPath}/.bun/bin ]]; then
        export PATH=$PATH:${config.flags.homeWorkPath}/.bun/bin
      fi

      # uv tool install directory
      export UV_TOOL_BIN_DIR="${config.flags.homeWorkPath}/.local/bin"
      export UV_TOOL_DIR="${config.flags.homeWorkPath}/.local/share/uv/tools"

      if [[ -d ${config.flags.homeWorkPath}/.local/bin ]]; then
        export PATH=$PATH:${config.flags.homeWorkPath}/.local/bin
      fi
      # Claude CLI lives in ~/.local/bin (hardcoded in binary)
      if [[ -d $HOME/.local/bin ]]; then
        export PATH=$PATH:$HOME/.local/bin
      fi
${lib.optionalString pkgs.stdenv.targetPlatform.isDarwin ''
      # Obsidian CLI
      if [[ -d /Applications/Obsidian.app/Contents/MacOS ]]; then
        export PATH=$PATH:/Applications/Obsidian.app/Contents/MacOS
      fi
''}
      # Require typing 'exit' to close shell (disable Ctrl+D)
      set -o ignoreeof
    '';
    profileExtra = ''
      # Ensure Nix paths are available in SSH sessions (for mosh-server)
      if [[ -d /etc/profiles/per-user/$USER/bin ]]; then
        export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
      fi
      export PATH="/run/current-system/sw/bin:$PATH"

      # Added by OrbStack: command-line tools and integration
      # This won't be added again if you remove it.
      source ~/.orbstack/shell/init.bash 2>/dev/null || :
    '';
  };
}
