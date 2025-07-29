{ pkgs, ... }:

{
  home.packages = [
    pkgs.mangohud
    (pkgs.writeScriptBin "gamescope-session" ''
      #!${pkgs.bash}/bin/bash

      set -xeuo pipefail

      gamescopeArgs=(
          --adaptive-sync # VRR support
          --hdr-enabled
          --mangoapp # performance overlay
          --rt
          --steam
      )

      steamArgs=(
          -pipewire-dmabuf
          -tenfoot
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

      echo "Starting gamescope session..."
      echo "This will launch a Steam Deck-like experience"
      echo "Press Ctrl+C to exit"

      exec ${pkgs.gamescope}/bin/gamescope "''${gamescopeArgs[@]}" -- ${pkgs.steam}/bin/steam "''${steamArgs[@]}"
    '')
  ];
}
