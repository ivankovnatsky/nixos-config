{
  config,
  ...
}:

let
  homePath = config.home.homeDirectory;

in
{
  local = {
    dock.enable = true;
    dock.username = config.home.username;
    dock.entries = [
      { path = "/System/Applications/Apps.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/Calendar.app/"; }
      { path = "/System/Applications/Contacts.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/System Settings.app/"; }

      {
        type = "spacer";
        section = "apps";
      }

      # Brew casks
      { path = "/Applications/kitty.app/"; }
      { path = "/Applications/Firefox Developer Edition.app/"; }
      { path = "/Applications/Chromium.app/"; }
      { path = "/Applications/Bitwarden.app/"; }
      { path = "/Applications/Obsidian.app/"; }
      { path = "/Applications/WhatsApp.app/"; }
      { path = "/Applications/coconutBattery.app/"; }

      {
        path = "${homePath}/Downloads/";
        section = "others";
      }
    ];
  };
}
