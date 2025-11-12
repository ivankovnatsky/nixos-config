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
      # Serialize dock entries to JSON for Python script
      entriesJSON = builtins.toJSON cfg.entries;
    in
    {
      local.launchd.services.dock-mgmt = {
        enable = true;
        type = "user-agent";
        label = "com.ivankovnatsky.dock-mgmt";
        command = "${pkgs.python3}/bin/python ${./dock.py} ${dockutil}/bin/dockutil '${entriesJSON}'";
        runAtLoad = true; # Run when agent is loaded/reloaded on rebuild
        keepAlive = false; # One-shot job - exit after completion
        environment = {
          PATH = "${pkgs.python3}/bin:${dockutil}/bin:/usr/bin:/bin";
        };
      };
    }
  );
}
