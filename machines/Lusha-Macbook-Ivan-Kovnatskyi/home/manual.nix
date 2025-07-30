{ config, lib, pkgs, ... }:
{
  home.activation = {
    installNpmPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Install global npm packages using nodejs from nix
      if [[ -x "${pkgs.nodejs}/bin/npm" ]]; then
        echo "Installing global npm packages..."
        $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm install --global \
          npm-groovy-lint \
          @anthropic-ai/claude-code
      else
        echo "Warning: nodejs package not available, skipping global package installation"
      fi
    '';
  };
}
