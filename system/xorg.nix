{ config, pkgs, ... }:

{
  imports = [
    ./i3.nix
    ./xserver-laptop.nix
  ];

  environment.systemPackages = with pkgs; [ arandr maim xclip xorg.xev ];

  environment = {
    variables = {
      BEMENU_SCALE = "1";
    };
  };

  services = {
    clipmenu.enable = true;

    xserver = {
      enable = true;

      dpi = config.device.xorgDpi;
      videoDrivers = [ config.device.videoDriver ];

      desktopManager.xterm.enable = false;

      displayManager = {
        lightdm.enable = true;

        autoLogin = {
          enable = true;
          user = "ivan";
        };
      };

      layout = "us,ua";
      xkbOptions = "grp:caps_toggle";

      extraConfig = ''
        Section "InputClass"
          Identifier "My Mouse"
          MatchIsPointer "yes"
          Option "AccelerationProfile" "-1"
          Option "AccelerationScheme" "none"
          Option "AccelSpeed" "-1"
        EndSection
      '';

      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
