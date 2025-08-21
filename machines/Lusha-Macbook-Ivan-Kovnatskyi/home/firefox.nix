{ config, pkgs, ... }:

let
  firefoxDevProfile = "1pnq61kq.dev-edition-default";
  firefoxProfile = "kfa2z0ty.default-release";
  userJsConfig = ''
      // Disable extension signature requirement for Tweety
      user_pref("xpinstall.signatures.required", false);

      // Enable vertical tabs
      user_pref("sidebar.verticalTabs", true);

      // Restore previous session (tabs and windows)
      user_pref("browser.startup.page", 3);

      // Enable Ctrl+Tab to cycle through recent tabs
      user_pref("browser.ctrlTab.recentlyUsedOrder", true);
      user_pref("browser.ctrlTab.sortByRecentlyUsed", true);
    '';
in
{
  home.packages = [ pkgs.passff-host ];
  home.file = {
    # Firefox Developer Edition user.js configuration
    "Library/Application Support/Firefox/Profiles/${firefoxDevProfile}/user.js".text = userJsConfig;

    # Install Tweety extension automatically
    "Library/Application Support/Firefox/Profiles/${firefoxDevProfile}/extensions/tweety@pomdtr.me.xpi" = {
      source = "${pkgs.tweety}/share/extensions/firefox.zip";
    };

    # Install Okta Browser Plugin
    "Library/Application Support/Firefox/Profiles/${firefoxDevProfile}/extensions/{b31c6c7d-29f1-4b34-a1e7-8b76bfabce3d}.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/okta-browser-plugin/addon-905837-latest.xpi";
        sha256 = "0ynlpb5a4c59z7v5jc2xfw1cll7sivrk5nszmfmp1ibvyvr4bdav";
      };
    };

    # Install Dark Reader
    "Library/Application Support/Firefox/Profiles/${firefoxDevProfile}/extensions/addon@darkreader.org.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/addon-607454-latest.xpi";
        sha256 = "1p1hmrpqcnx8p218c8m148rz1z3n40xlk03lb441mk3hcj14aql4";
      };
    };

    # Install PassFF
    "Library/Application Support/Firefox/Profiles/${firefoxDevProfile}/extensions/passff@invicem.pro.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/passff/addon-372917-latest.xpi";
        sha256 = "0sa7alk3i77w27a768sm1jg0fdqz471lgfff91wllsnkm4c6sgbf";
      };
    };

    # Install Automatic Dark
    "Library/Application Support/Firefox/Profiles/${firefoxDevProfile}/extensions/{b19a1b81-c296-4c8b-9b60-df8a6ef31fc7}.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/automatic-dark/addon-1394019-latest.xpi";
        sha256 = "133alh7rbc06k7b1vpgq39fbi86c07i67qmd9ymra1lncwjw9vvp";
      };
    };

    # PassFF native messaging host symlink
    "Library/Application Support/Mozilla/NativeMessagingHosts/passff.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/mozilla/native-messaging-hosts/passff.json";
    };

    # Firefox
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/user.js".text = userJsConfig;

    # Install Okta Browser Plugin
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/extensions/{b31c6c7d-29f1-4b34-a1e7-8b76bfabce3d}.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/okta-browser-plugin/addon-905837-latest.xpi";
        sha256 = "0ynlpb5a4c59z7v5jc2xfw1cll7sivrk5nszmfmp1ibvyvr4bdav";
      };
    };

    # Install Dark Reader
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/extensions/addon@darkreader.org.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/addon-607454-latest.xpi";
        sha256 = "1p1hmrpqcnx8p218c8m148rz1z3n40xlk03lb441mk3hcj14aql4";
      };
    };

    # Install PassFF
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/extensions/passff@invicem.pro.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/passff/addon-372917-latest.xpi";
        sha256 = "0sa7alk3i77w27a768sm1jg0fdqz471lgfff91wllsnkm4c6sgbf";
      };
    };

    # Install Automatic Dark
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/extensions/{b19a1b81-c296-4c8b-9b60-df8a6ef31fc7}.xpi" = {
      source = builtins.fetchurl {
        url = "https://addons.mozilla.org/firefox/downloads/latest/automatic-dark/addon-1394019-latest.xpi";
        sha256 = "133alh7rbc06k7b1vpgq39fbi86c07i67qmd9ymra1lncwjw9vvp";
      };
    };
  };
}
