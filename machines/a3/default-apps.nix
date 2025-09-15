{ pkgs, ... }:

{
  # Default application associations

  # Set Firefox Developer Edition as the default browser
  xdg.mime.defaultApplications = {
    "text/html" = "firefox-devedition.desktop";
    "x-scheme-handler/http" = "firefox-devedition.desktop";
    "x-scheme-handler/https" = "firefox-devedition.desktop";
    "x-scheme-handler/about" = "firefox-devedition.desktop";
    "x-scheme-handler/unknown" = "firefox-devedition.desktop";
  };

  environment.sessionVariables = {
    DEFAULT_BROWSER = "${pkgs.nixpkgs-master.firefox-devedition}/bin/firefox";
  };
}
