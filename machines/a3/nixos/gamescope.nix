# https://wiki.nixos.org/wiki/Steam#Gamescope_Compositor_/_%22Boot_to_Steam_Deck%22
# Clean Quiet Boot

{ pkgs, username, ... }:
{
  # TODO:
  # - Only WIFI needed?
  # - Running under another user? No Steam config there.
  boot = {
    kernelParams = [
      "quiet"
      "splash"
      # FIXME: Does this disable virtual console?
      # "console=/dev/null"
    ];
    plymouth.enable = true;
  };

  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam.gamescopeSession.enable = true; # Integrates with programs.steam
  };

  # Gamescope Auto Boot from TTY (example)
  services = {
    xserver.enable = false; # Assuming no other Xserver needed
    getty.autologinUser = username;

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f -e --xwayland-count 2 --hdr-enabled --hdr-itm-enabled -- steam -pipewire-dmabuf -gamepadui -steamdeck -steamos3 > /dev/null 2>&1";
          user = username;
        };
      };
    };
  };
}
