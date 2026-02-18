{ config, username, ... }:

let
  homePath = "${config.users.users.${username}.home}";
in
{
  local.services.syncthing-mgmt = {
    # Folders can reference devices by name (resolved from deviceDefinitionsFile)
    folders = {
      # WARNING: This path is iCloud-synced via Obsidian. Only share from Air
      # to a3 — do not add pro or mini, they have their own iCloud sync.
      "notes" = {
        path = "${homePath}/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
        label = "Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
        devices = [
          "Ivans-MacBook-Air"
          "a3"
        ];
      };
    };
  };
}
