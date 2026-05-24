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
  # Re-import the live X / Wayland session env into the systemd --user
  # manager on every Plasma login. With Linger=yes the user manager
  # survives across logout/login and otherwise keeps a stale XAUTHORITY
  # from a previous SDDM session, which makes dock-launched apps
  # (transient app-*.service units) crash with "Authorization required,
  # but no authorization protocol specified" on Xwayland.
  xdg.configFile."plasma-workspace/env/10-import-systemd-env.sh".text = ''
    systemctl --user import-environment \
      DISPLAY \
      XAUTHORITY \
      WAYLAND_DISPLAY \
      XDG_SESSION_TYPE
  '';

  # Override the system steam.desktop to drop GPU-routing hints that
  # misbehave on hybrid RTX + AMD iGPU Wayland Plasma 6
  # (KDE bug 480797). Per-game `nvidia-offload %command%` is the
  # NixOS-recommended path when offload is actually wanted.
  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Game Launcher";
    comment = "Application for managing and playing games on Steam";
    exec = "${steamLauncher} %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [
      "Network"
      "FileTransfer"
      "Game"
    ];
    mimeType = [
      "x-scheme-handler/steam"
      "x-scheme-handler/steamlink"
    ];
    prefersNonDefaultGPU = false;
    settings = {
      "X-KDE-RunOnDiscreteGpu" = "false";
    };
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
