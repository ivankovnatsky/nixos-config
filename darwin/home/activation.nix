{ config, lib, pkgs, ... }:
{
  home.activation = {
    homeActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
      cat <<EOF > $HOME/.npmrc
        prefix=~/.npm
      EOF

      # Check if packages are already installed
      if [[ ! -x "$HOME/.npm/bin/claude" || \
            ! -x "$HOME/.npm/bin/codex" || \
            ! -x "$HOME/.npm/bin/gemini" ]]; then
        echo "Installing missing npm packages..."
        export PATH="${pkgs.nodejs}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.curl}/bin:$PATH"
        ${pkgs.nodejs}/bin/npm install --global --force \
          @anthropic-ai/claude-code \
          @openai/codex \
          @google/gemini-cli
      else
        echo "All npm packages already installed, skipping..."
      fi
    '';
  };
}