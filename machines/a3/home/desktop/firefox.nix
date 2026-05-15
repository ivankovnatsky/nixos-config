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
      bitwarden
    ];
  };

  configPath = ".mozilla/firefox";
  configPathAbs = "${config.home.homeDirectory}/${configPath}";

in
{
  home.packages = [ pkgs.tweety ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    inherit configPath;

    policies = {
      ExtensionSettings = {
        "selecttab@ivankovnatsky.net" = {
          installation_mode = "force_installed";
          install_url = "file://${configPathAbs}/dev-edition-default/extensions/selecttab@ivankovnatsky.net.xpi";
        };
        "tweety@pomdtr.me" = {
          installation_mode = "force_installed";
          install_url = "file://${configPathAbs}/dev-edition-default/extensions/tweety@pomdtr.me.xpi";
        };
      };
    };

    profiles = {
      "dev-edition-default" = commonSettings // {
        id = 0;
        isDefault = true;
        settings = commonSettings.settings // {
          # Disable extension signature requirement for unsigned extensions
          "xpinstall.signatures.required" = false;
        };
      };
      "default" = commonSettings // {
        id = 1;
      };
    };
  };

  home.file = {
    "${configPath}/dev-edition-default/extensions/tweety@pomdtr.me.xpi" = {
      source = "${pkgs.tweety}/share/extensions/firefox.zip";
    };
    "${configPath}/dev-edition-default/extensions/selecttab@ivankovnatsky.net.xpi" = {
      source = "${pkgs.firefox-selecttab}/share/extensions/firefox-selecttab.zip";
    };
    "${configPath}/default/extensions/selecttab@ivankovnatsky.net.xpi" = {
      source = "${pkgs.firefox-selecttab}/share/extensions/firefox-selecttab.zip";
    };
  };
}
