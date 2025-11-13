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
    # Use pinned master commit for development shell
    pkgs = import inputs.nixpkgs-master-pinned { inherit system; };
  in
  {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Version control
        git
        gh
        gnupg
        pinentry-tty

        # Development tools
        tmux
        gnumake
        vim

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
        export EDITOR="vim"
        export VISUAL="vim"
        export GPG_TTY=$(tty)

        # Configure GPG agent with pinentry-tty if config doesn't exist
        if [ ! -f ~/.gnupg/gpg-agent.conf ]; then
          mkdir -p ~/.gnupg
          echo "pinentry-program $(which pinentry-tty)" >> ~/.gnupg/gpg-agent.conf
          gpgconf --kill gpg-agent 2>/dev/null || true
        fi

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
          exec fish -C "set -gx GIT_CONFIG_GLOBAL $GIT_CONFIG_GLOBAL; set -gx GPG_TTY (tty); alias g='git'"
        fi
      '';
    };
  }
)
