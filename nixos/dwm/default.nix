{ config, pkgs, ... }:

{
  programs = {
    slock.enable = true;
  };

  # Display manager options for dwm (choose one):
  
  # Option 1: LightDM (lightweight graphical login)
  # services.xserver.displayManager.lightdm.enable = true;
  
  # Option 2: Auto-login (boots directly into dwm session)
  # services.xserver.displayManager.autoLogin = {
  #   enable = true;
  #   user = "ivan";
  # };
  
  # Option 3: startx/xinit (manual start from console)
  # services.xserver.displayManager.startx.enable = true;
  # After console login, run: startx
  
  # Option 4: SDDM (from KDE, heavier but feature-rich)
  # services.displayManager.sddm.enable = true;
  
  # Note: If none are enabled, you'll get console login only
  # and need to start X manually

  services.xserver.windowManager.dwm = {
    enable = true;
    package = pkgs.dwm.override {
      conf = builtins.readFile ./files/suckless/dwm/config.h;
      patches = [
        (pkgs.fetchpatch {
          url = "https://dwm.suckless.org/patches/notitle/dwm-notitle-6.2.diff";
          sha256 = "0lr7l98jc88lwik3hw22jq7pninmdla360c3c7zsr3s2hiy39q9f";
        })
        (pkgs.fetchpatch {
          url = "https://dwm.suckless.org/patches/pwkl/dwm-pwkl-6.2.diff";
          sha256 = "0qq3mlcp55p5dx9jmd75rkxlsdihzh4a2z1qzpljqash14kqsqzm";
        })
      ];
    };
    extraSessionCommands = ''
      ${pkgs.slstatus}/bin/slstatus &
    '';
  };

  environment.systemPackages = with pkgs; [
    dmenu
    pamixer

    (slstatus.override {
      conf = builtins.readFile ./files/suckless/slstatus/config.h;
    })

    (st.override { conf = builtins.readFile ./files/suckless/st/config.h; })
  ];
}