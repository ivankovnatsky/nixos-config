{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
in
{
  options = {
    local.dock.enable = mkOption {
      description = "Enable dock";
      default = stdenv.isDarwin;
      example = false;
    };

    local.dock.entries = mkOption {
      description = "Entries on the Dock";
      type =
        with types;
        listOf (submodule {
          options = {
            path = lib.mkOption { type = str; };
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
      primaryUser = config.system.primaryUser;
    in
    {
      system.activationScripts.setupDock.text = ''
        echo >&2 "Setting up the Dock for ${primaryUser}..."
        # Run dockutil as the primary user
        sudo -u ${primaryUser} bash -c '
          haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
          if ! diff -wu <(echo -n "$haveURIs") <(echo -n '"'"'${wantURIs}'"'"') >&2 ; then
            echo >&2 "Resetting Dock."
            ${dockutil}/bin/dockutil --no-restart --remove all
            ${createEntries}
            killall Dock
          else
            echo >&2 "Dock setup complete."
          fi
        '
      '';
    }
  );
}
