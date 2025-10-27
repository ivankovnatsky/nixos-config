{
  config,
  lib,
  pkgs,
  ...
}:

{
  # KDE Plasma display configuration with 200% scaling
  # Note: plasma-manager doesn't support monitor configuration yet
  # See: https://github.com/nix-community/plasma-manager/issues/172
  #
  # We copy the kwinoutputconfig.json file but only if it differs
  # This allows KDE to update the file during runtime

  home.file.".config/kwinoutputconfig.json" = {
    source = ./kwinoutputconfig.json;
    # Don't force overwrite if the file exists and is different
    # This allows KDE to manage the file during runtime
    force = false;
    onChange = ''
      # Check if the runtime config differs from our managed version
      if [ -f ~/.config/kwinoutputconfig.json ]; then
        if ! diff -q ${./kwinoutputconfig.json} ~/.config/kwinoutputconfig.json > /dev/null 2>&1; then
          echo "⚠️  kwinoutputconfig.json has changed! Showing differences:"
          echo "────────────────────────────────────────────────────────"
          diff -u ${./kwinoutputconfig.json} ~/.config/kwinoutputconfig.json || true
          echo "────────────────────────────────────────────────────────"
          echo "To update the nix config, run:"
          echo "  cp ~/.config/kwinoutputconfig.json ~/Sources/github.com/ivankovnatsky/nixos-config/machines/steamdeck/home/kwinoutput/kwinoutputconfig.json"
        fi
      fi
    '';
  };
}
