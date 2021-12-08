{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ xdg-utils ];
  xdg = {
    icons.enable = true;

    mime = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "firefox.desktop";
        "image/png" = "firefox.desktop";
      };
    };
  };
}
