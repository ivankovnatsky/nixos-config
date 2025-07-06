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
      { path = "/System/Library/CoreServices/Applications/Keychain Access.app/"; }
      { path = "/Applications/Numbers.app/"; }
      { path = "/System/Applications/iPhone Mirroring.app/"; }
      { path = "/System/Applications/FindMy.app/"; }
      { path = "/System/Applications/Weather.app/"; }
      { path = "/System/Applications/Home.app/"; }
      { path = "/System/Applications/Utilities/Screen Sharing.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Brew casks placeholder
      { path = "/Applications/Firefox.app/"; }
      { path = "/Applications/Chromium.app/"; }
      { path = "/Applications/Bitwarden.app/"; }
      { path = "/Applications/Cursor.app/"; }
      { path = "/Applications/Windsurf.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Installed using nixpkgs
      { path = "/Applications/Ghostty.app/"; }
      { path = "${pkgs.coconutbattery}/Applications/coconutBattery.app/"; }
      { path = "${pkgs.keycastr}/Applications/KeyCastr.app/"; }

      {
        path = "${homePath}/Downloads/";
        section = "others";
      }
    ];
  };
}
