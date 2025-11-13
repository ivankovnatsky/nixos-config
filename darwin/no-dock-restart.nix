{ config, lib, pkgs, ... }:

# Override nix-darwin's default behavior of restarting Dock when system.defaults.dock.* changes
# This prevents the flickering/disruption during darwin-rebuild
# We wrap killall to ignore Dock restart requests

{
  system.activationScripts.preActivation.text = lib.mkBefore ''
        # Create a wrapper for killall that ignores Dock
        REAL_KILLALL="$(command -v killall)"
        export REAL_KILLALL
        mkdir -p /tmp/nix-darwin-no-dock-restart
        cat > /tmp/nix-darwin-no-dock-restart/killall <<'EOF'
    #!/bin/bash
    # Filter out Dock from killall commands during activation
    if [[ "$*" == *"Dock"* ]]; then
      echo >&2 "Dock defaults applied (restart skipped to avoid flickering)"
      exit 0
    else
      exec "$REAL_KILLALL" "$@"
    fi
    EOF
        chmod +x /tmp/nix-darwin-no-dock-restart/killall
        export PATH="/tmp/nix-darwin-no-dock-restart:$PATH"
  '';

  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Clean up the wrapper
    rm -rf /tmp/nix-darwin-no-dock-restart
  '';
}
