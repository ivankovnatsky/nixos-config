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
      
      # Generate dock entries as simple commands for the heredoc
      formatSpacerEntry = section: "${dockutil}/bin/dockutil --no-restart --add '' --type spacer --section ${section}";
      formatAppEntry = entry: "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}";
      
      # Generate the entries script
      entriesScript = concatMapStringsSep "\n" (
        entry: if entry.type == "spacer" 
               then formatSpacerEntry entry.section
               else formatAppEntry entry
      ) cfg.entries;
      
      # Escape the wantURIs string for inclusion in the script
      escapedWantURIs = replaceStrings ["'"] ["'\\''"] wantURIs;
      primaryUser = config.system.primaryUser;
    in
    {
      # https://github.com/nix-darwin/nix-darwin/issues/1462#issuecomment-2895299811
      system.activationScripts.postActivation.text = ''
        echo >&2 "Setting up the Dock for ${primaryUser}..."
        
        # Create a temp file with appropriate permissions
        DOCK_SCRIPT=$(mktemp)
        
        # Write script to temp file
        cat > "$DOCK_SCRIPT" << 'EOL'
        #!/bin/bash
        DOCK_UTIL="${dockutil}/bin/dockutil"
        haveURIs="$($DOCK_UTIL --list | ${pkgs.coreutils}/bin/cut -f2)"
        
        WANT_URIS='${escapedWantURIs}'
        
        if ! diff -wu <(echo -n "$haveURIs") <(echo -n "$WANT_URIS") >&2 ; then
          echo >&2 "Resetting Dock."
          $DOCK_UTIL --no-restart --remove all
          
          # Add dock entries
          ${entriesScript}
          
          killall Dock
        else
          echo >&2 "Dock setup complete."
        fi
        EOL
        
        # Make script readable and executable for everyone
        chmod 755 "$DOCK_SCRIPT"
        
        # Run the script as the user
        sudo -u ${primaryUser} "$DOCK_SCRIPT"
        
        # Clean up
        rm "$DOCK_SCRIPT"
      '';
    }
  );
}
