{
  config,
  pkgs,
  username,
  ...
}:

let
  homePath = "${config.users.users.${username}.home}";

in
{
  local = {
    dock.enable = true;
    dock.username = username;
    # TODO: can dock be stretched 100% horizontally?
    dock.entries = [
      # Default macOS apps
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Additional macOS apps
      { path = "/System/Applications/Utilities/Terminal.app/"; }
      { path = "/System/Applications/Preview.app"; }
      { path = "/System/Applications/Passwords.app/"; }
      { path = "/System/Library/CoreServices/Applications/Keychain Access.app"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Installed using Kandji
      { path = "/Applications/Google Chrome.app/"; }
      { path = "/Applications/Slack.app/"; }
      { path = "/Applications/zoom.us.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Installed using homebrew
      { path = "/Applications/Chromium.app/"; }
      { path = "/Applications/DBeaver.app/"; }
      { path = "/Applications/Cursor.app/"; }
      { path = "/Applications/Windsurf.app/"; }
      { path = "/Applications/MindMac.app/"; }
      { path = "/Applications/Bitwarden.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # nixpkgs installed
      { path = "/Applications/Ghostty.app/"; }
      { path = "${pkgs.vscode}/Applications/Visual Studio Code.app/"; }
      { path = "${pkgs.keycastr}/Applications/KeyCastr.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Safari Web Apps
      { path = "${homePath}/Applications/ChatGPT Web.app/"; }
      { path = "${homePath}/Applications/Claude Web.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      { path = "${homePath}/Applications/Тривога.app/"; }

      {
        path = "${config.users.users.${username}.home}/Downloads/";
        section = "others";
      }
    ];
  };
}
