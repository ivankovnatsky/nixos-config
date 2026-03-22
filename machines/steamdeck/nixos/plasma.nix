{
  pkgs,
  ...
}:

{
  services = {
    desktopManager.plasma6.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = "*";
  };

  environment.systemPackages = with pkgs; [
    maliit-keyboard
    maliit-framework
  ];
}
