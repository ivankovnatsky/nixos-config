{ pkgs, ... }:

let
  defaultBrowserDesktop = "firefox-devedition.desktop";
  defaultBrowserBin =  "${pkgs.firefox-devedition}/bin/firefox";
in
{
  # Default application associations
  xdg.mime.defaultApplications = {
    "text/html" = defaultBrowserDesktop;
    "x-scheme-handler/http" = defaultBrowserDesktop;
    "x-scheme-handler/https" = defaultBrowserDesktop;
    "x-scheme-handler/about" = defaultBrowserDesktop;
    "x-scheme-handler/unknown" = defaultBrowserDesktop;
  };

  environment.sessionVariables = {
    DEFAULT_BROWSER = defaultBrowserBin;
  };
}
