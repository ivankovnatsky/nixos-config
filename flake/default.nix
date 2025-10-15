{ inputs, ... }:
let
  machines = import ./machines { inherit inputs; };

  # Development shell for working on this config
  forAllSystems = inputs.flake-utils.lib.eachDefaultSystem;
in
{
  inherit (machines) darwinConfigurations nixosConfigurations;
  overlay = import ./overlay.nix { inherit inputs; };
}
// forAllSystems (system:
  let
    pkgs = import inputs.nixpkgs-darwin-unstable { inherit system; };
  in
  {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Version control
        git
        git-crypt
        gnupg
        pinentry

        # Development tools
        tmux
        gnumake
        neovim

        # Nix tools
        nixfmt-rfc-style
        nixpkgs-fmt
        nil # Nix LSP

        # Shell tools
        ripgrep
        fd
        jq
        fish

        # Node.js for npm-installed packages (like claude)
        nodejs
      ];

      shellHook = ''
        export GIT_CONFIG_GLOBAL="$PWD/home/git/config"
        export EDITOR="nvim"
        export VISUAL="nvim"

        # Install claude if not present
        if [[ ! -x "$HOME/.npm/bin/claude" ]]; then
          echo "Installing Claude Code CLI..."
          npm install --global --force @anthropic-ai/claude-code
        fi

        # Add npm global bin directory to PATH for claude and other npm packages
        if [ -d "$HOME/.npm/bin" ]; then
          export PATH="$HOME/.npm/bin:$PATH"
        fi

        # Launch fish shell with git alias and environment
        if command -v fish >/dev/null 2>&1; then
          exec fish -C "set -gx GIT_CONFIG_GLOBAL $GIT_CONFIG_GLOBAL; alias g='git'"
        fi
      '';
    };
  }
)
