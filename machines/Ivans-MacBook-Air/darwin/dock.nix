{ config, pkgs, username, ... }:

let
  homePath = "${config.users.users.${username}.home}";

in
{
  local = {
    dock.enable = true;
    # TODO: can dock be streched 100% horizontally?
    dock.entries = [
      { path = "/System/Applications/Launchpad.app/"; }
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "/System/Applications/Maps.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/FaceTime.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Contacts.app/"; }
      { path = "/System/Applications/Reminders.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/System/Applications/TV.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/Podcasts.app/"; }
      { path = "/System/Applications/App Store.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      { path = "/System/Applications/Utilities/Terminal.app/"; }
      { path = "/System/Applications/Utilities/Activity Monitor.app/"; }
      { path = "/System/Applications/Preview.app"; }
      { path = "/System/Applications/Passwords.app/"; }
      { path = "/Applications/Numbers.app/"; }
      { path = "/System/Library/CoreServices/Applications/Keychain Access.app/"; }
      { path = "/System/Applications/iPhone Mirroring.app/"; }
      { path = "/System/Applications/FindMy.app/"; }
      { path = "/System/Applications/Utilities/Screen Sharing.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      { path = "/Applications/kitty.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/Vivaldi.app/"; }
      { path = "/Applications/Bitwarden.app/"; }
      { path = "/Applications/Cursor.app/"; }
      { path = "/Applications/Windsurf.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Installed using nixpkgs
      { path = "/Applications/Ghostty.app/"; }
      { path = "${pkgs.vscode}/Applications/Visual Studio Code.app/"; }
      { path = "${pkgs.coconutbattery}/Applications/coconutBattery.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # TODO: see if making a Dock web app could be automated.
      { path = "${homePath}/Applications/Тривога.app/"; }
      { path = "${homePath}/Applications/X.app/"; }
      { path = "${homePath}/Applications/WhatsApp Web.app/"; }
      { path = "${homePath}/Applications/Telegram Web.app/"; }
      { path = "${homePath}/Applications/ChatGPT.app/"; }
      { path = "${homePath}/Applications/Claude.app/"; }
      { path = "${homePath}/Applications/OLX.ua.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      { path = "/Applications/Microsoft Teams.app/"; }

      {
        path = "${homePath}/Downloads/";
        section = "others";
      }
    ];
  };
}
