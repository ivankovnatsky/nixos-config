{ config, pkgs, ... }:

{
  programs = {
    slock.enable = true;
  };

  # Display manager options for dwm (choose one):
  
  # Option 1: LightDM (lightweight graphical login)
  # services.xserver.displayManager.lightdm.enable = true;
  
  # Note: a3 already has LightDM enabled, so no need to enable another display manager.
  # LightDM will automatically show dwm as a session option after rebuild.
  
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

  # dwm patches reference: https://dwm.suckless.org/patches/
  # Note: nixpkgs uses dwm 6.5, so patches must be compatible with that version
  # HiDPI configuration for 4K displays
  services.xserver.dpi = 144;  # 1.5x scaling (96 * 1.5 = 144)
  
  # Set DPI for GTK and Qt applications
  environment.variables = {
    GDK_SCALE = "1.5";
    GDK_DPI_SCALE = "1";
    QT_SCALE_FACTOR = "1.5";
    XCURSOR_SIZE = "32";
  };

  services.xserver.windowManager.dwm = {
    enable = true;
    package = pkgs.dwm.override {
      conf = builtins.readFile ./files/suckless/dwm/config.h;
      patches = [
        (pkgs.fetchpatch {
          url = "https://dwm.suckless.org/patches/notitle/dwm-notitle-6.5.diff";
          sha256 = "sha256-RDgSj2p4Ki2YKyFXjpKJn8Kk0ouY4eiLWue6KnbOF18=";
        })
        # pwkl patch only available up to 6.2, may need manual adaptation
        # (pkgs.fetchpatch {
        #   url = "https://dwm.suckless.org/patches/pwkl/dwm-pwkl-6.2.diff";
        #   sha256 = "sha256-2EOhzJE+qqQSl5ti9+Gj2QWex+P1sFSWx9pQ8DAp5jg=";
        # })
      ];
    };
    extraSessionCommands = ''
      # Set DPI for X applications
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
      Xft.dpi: 144
      Xcursor.size: 32
      EOF
      
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