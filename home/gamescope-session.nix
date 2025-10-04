{ pkgs, ... }:

{
  home.packages = [
    pkgs.mangohud
    (pkgs.writeScriptBin "gamescope-session" ''
      #!${pkgs.bash}/bin/bash

      set -xeuo pipefail

      gamescopeArgs=(
          -W 1920 -H 1080 # Resolution
          -f # Fullscreen
          -e # Steam integration
          --xwayland-count 2 # Multiple Xwayland instances
          --adaptive-sync # VRR support
          --hdr-enabled
          --hdr-itm-enabled # HDR tone mapping
          --mangoapp # performance overlay
          --rt
          --steam
      )

      steamArgs=(
          -pipewire-dmabuf
          -gamepadui # Steam Deck UI
          -steamdeck # Steam Deck mode
          -steamos3 # SteamOS 3 compatibility
      )

      mangoConfig=(
          cpu_temp
          gpu_temp
          ram
          vram
      )

      mangoVars=(
          MANGOHUD=1
          MANGOHUD_CONFIG="$(IFS=,; echo "''${mangoConfig[*]}")"
      )

      export "''${mangoVars[@]}"

      echo "Stopping display manager..."

      # Stop SDDM display manager (cleaner approach)
      sudo systemctl stop display-manager || true

      # Give display manager time to stop
      sleep 3

      echo "Starting gamescope session..."
      echo "This will launch a Steam Deck-like experience"
      echo "Press Ctrl+C to exit"

      exec ${pkgs.gamescope}/bin/gamescope "''${gamescopeArgs[@]}" -- ${pkgs.steam}/bin/steam "''${steamArgs[@]}"
    '')
  ];
}
