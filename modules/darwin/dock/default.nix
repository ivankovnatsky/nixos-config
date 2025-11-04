{
  config,
  pkgs,
  lib,
  ...
}:
# Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd
# Current source: https://github.com/dustinlyons/nixos-config/blob/main/modules/darwin/dock/default.nix

with lib;
let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
in
{
  options = {
    local.dock = {
      enable = mkOption {
        description = "Enable dock";
        default = stdenv.isDarwin;
      };

      entries = mkOption {
        description = "Entries on the Dock";
        type =
          with types;
          listOf (submodule {
            options = {
              path = lib.mkOption {
                type = str;
                default = ""; # Path is optional for spacers
              };
              section = lib.mkOption {
                type = str;
                default = "apps";
              };
              options = lib.mkOption {
                type = str;
                default = "";
              };
              type = lib.mkOption {
                type = str;
                default = "";
                description = "Type of the dock item (e.g., app, spacer)";
              };
            };
          });
        readOnly = true;
      };

      username = mkOption {
        description = "Username to apply the dock settings to";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable (
    let
      normalize = path: if hasSuffix ".app" path then path + "/" else path;
      entryURI =
        entry:
        if entry.type == "spacer" then
          ""
        else
          "file://"
          + (builtins.replaceStrings
            [
              " "
              "!"
              "\""
              "#"
              "$"
              "%"
              "&"
              "'"
              "("
              ")"
            ]
            [
              "%20"
              "%21"
              "%22"
              "%23"
              "%24"
              "%25"
              "%26"
              "%27"
              "%28"
              "%29"
            ]
            (normalize entry.path)
          );
      wantURIs = concatMapStrings (
        entry: if entry.type == "spacer" then "\n" else "${entryURI entry}\n"
      ) cfg.entries;
      createEntries = concatMapStrings (
        entry:
        if entry.type == "spacer" then
          "${dockutil}/bin/dockutil --no-restart --add '' --type spacer --section ${entry.section}\n"
        else
          "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n"
      ) cfg.entries;
    in
    {
      system.activationScripts.postActivation.text = ''
          echo >&2 "Setting up the Dock for ${cfg.username}..."
          sudo -u ${cfg.username} /bin/bash <<'USERBLOCK'
        # Get current dock items
        haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
        wantURIs='${wantURIs}'

        # Check if dock needs updating
        if diff -q <(echo -n "$haveURIs") <(echo -n "$wantURIs") >/dev/null 2>&1; then
          echo >&2 "Dock is already up to date."
          exit 0
        fi

        echo >&2 "Updating Dock (adding missing items only, no restart)..."

        # Check each wanted item and add if missing
        ${concatMapStrings (
          entry:
          if entry.type == "spacer" then
            ""
          else
            let
              uri = entryURI entry;
            in
            ''
              if ! echo "$haveURIs" | grep -Fxq '${uri}'; then
                echo >&2 "Adding: ${entry.path}"
                ${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options} 2>/dev/null || echo >&2 "Warning: Failed to add ${entry.path}"
              fi
            ''
        ) cfg.entries}

        echo >&2 "Dock updated without restart. Changes will appear shortly."
        USERBLOCK
      '';
    }
  );
}
