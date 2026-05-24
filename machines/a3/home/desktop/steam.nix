{ pkgs, ... }:

let
  steamLauncher = pkgs.writeShellScript "steam-launcher" ''
    if [ $# -eq 0 ]; then
      exec steam -start steam://open/bigpicture
    else
      exec steam "$@"
    fi
  '';
in
{
  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Game Launcher";
    comment = "Application for managing and playing games on Steam";
    icon = "steam";
    type = "Application";
    terminal = false;
    exec = "${steamLauncher} %U";
    categories = [
      "Network"
      "FileTransfer"
      "Game"
    ];
    mimeType = [
      "x-scheme-handler/steam"
      "x-scheme-handler/steamlink"
    ];
    actions = {
      Store = {
        name = "Store";
        exec = "steam steam://store";
      };
      Community = {
        name = "Community";
        exec = "steam steam://url/CommunityHome/";
      };
      Library = {
        name = "Library";
        exec = "steam steam://open/games";
      };
      Servers = {
        name = "Servers";
        exec = "steam steam://open/servers";
      };
      Screenshots = {
        name = "Screenshots";
        exec = "steam steam://open/screenshots";
      };
      News = {
        name = "News";
        exec = "steam steam://openurl/https://store.steampowered.com/news";
      };
      Settings = {
        name = "Settings";
        exec = "steam steam://open/settings";
      };
      BigPicture = {
        name = "Big Picture";
        exec = "steam steam://open/bigpicture";
      };
      Friends = {
        name = "Friends";
        exec = "steam steam://open/friends";
      };
    };
  };
}
