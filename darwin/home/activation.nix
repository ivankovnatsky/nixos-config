{ config, lib, pkgs, ... }:
{
  home.activation = {
    homeActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Check if packages are already installed
      if [[ ! -x "$HOME/.npm/bin/claude" || \
            ! -x "$HOME/.npm/bin/codex" || \
            ! -x "$HOME/.npm/bin/gemini" || \
            ! -x "$HOME/.npm/bin/happy" ]]; then
        echo "Installing missing npm packages..."
        export PATH="${pkgs.nodejs}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.curl}/bin:$PATH"
        ${pkgs.nodejs}/bin/npm install --global --force \
          @anthropic-ai/claude-code \
          @openai/codex \
          happy-coder \
          @google/gemini-cli
      else
        echo "All npm packages already installed, skipping..."
      fi
    '';
  };
}
