{ lib, pkgs, ... }:

let
  configFile = ./amethyst.yml;
in
{
  home.file.".config/amethyst/amethyst.yml".source = configFile;

  home.activation.amethystRestart = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    HASH_FILE="''${XDG_STATE_HOME:-$HOME/.local/state}/amethyst-config-hash"
    CURRENT_HASH=$(/usr/bin/shasum -a 256 ${configFile} | /usr/bin/cut -d' ' -f1)
    STORED_HASH=$(/bin/cat "$HASH_FILE" 2>/dev/null || echo "")
    if [ "$CURRENT_HASH" != "$STORED_HASH" ]; then
      ${pkgs.settings}/bin/settings windows restart Amethyst
      echo "$CURRENT_HASH" > "$HASH_FILE"
    fi
  '';
}
