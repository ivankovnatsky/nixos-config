{ config, pkgs, ... }:

let
  commonSettings = {
    settings = {
      # Enable vertical tabs
      "sidebar.verticalTabs" = true;

      # Restore previous session (tabs and windows)
      "browser.startup.page" = 3;

      # Enable Ctrl+Tab to cycle through recent tabs
      "browser.ctrlTab.recentlyUsedOrder" = true;
      "browser.ctrlTab.sortByRecentlyUsed" = true;
    };

    extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
      darkreader
      bitwarden
    ];
  };

in
{
  home.packages = [ pkgs.tweety ];

  programs.firefox = {
    enable = true;
    # package = pkgs.nixpkgs-master.firefox-devedition;
    profiles = {
      "dev-edition-default" = commonSettings // {
        id = 0;
        isDefault = true;
        settings = commonSettings.settings // {
          # Disable extension signature requirement for Tweety
          "xpinstall.signatures.required" = false;
        };
      };
      "default" = commonSettings // {
        id = 1;
      };
    };
  };

  home.file = {
    # Install Tweety extension manually
    ".mozilla/firefox/dev-edition-default/extensions/tweety@pomdtr.me.xpi" = {
      source = "${pkgs.tweety}/share/extensions/firefox.zip";
    };
  };
}
