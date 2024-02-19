{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
    # firefox-translations
    # granted-containers
    bitwarden
    clearurls
    darkreader
    decentraleyes
    duckduckgo-privacy-essentials
    # https-everywhere
    multi-account-containers
    onepassword-password-manager
    privacy-badger
    # To disable all those tree shenanigans:
    # https://github.com/piroor/treestyletab/issues/1544#issuecomment-522902490
    # tree-style-tab
    ublock-origin
  ];

  defaultSettings = {
    "browser.contentblocking.category" = "strict";
    "browser.ctrlTab.recentlyUsedOrder" = true;
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    "browser.download.dir" = "/tmp";
    "browser.engagement.ctrlTab.has-used" = true;
    "browser.fullscreen.autohide" = false;
    "browser.safebrowsing.appRepURL" = "";
    "browser.safebrowsing.malware.enabled" = false;
    "browser.search.hiddenOneOffs" = "Google,Yahoo,Bing,Amazon.com,Twitter";
    "browser.search.suggest.enabled" = false;
    "browser.send_pings" = false;
    "browser.startup.page" = 3;
    "browser.toolbars.bookmarks.visibility" = "never";
    "dom.security.https_only_mode" = true;
    "extensions.pocket.enabled" = false;
    "general.smoothScroll" = true;
    "geo.enabled" = false;
    "network.allow-experiments" = false;
    "network.dns.disablePrefetch" = true;
    "permissions.default.desktop-notification" = 2;
    "privacy.donottrackheader.enabled" = true;
    "privacy.donottrackheader.value" = 1;
    "security.sandbox.content.level" = 3;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "app.update.silent" = true;
    "app.update.url.details" = "https://non-existent-site";
    "app.update.url.manual" = "https://non-existent-site";
  };

  defaultLinuxSettingsTemplate = {
    "media.videocontrols.picture-in-picture.enabled" = false;
    "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
    "media.videocontrols.picture-in-picture.video-toggle.has-used" = false;
    "widget.wayland-dmabuf-vaapi.enabled" = true;
    "gfx.webrender.all" = true;
  };

  defaultLinuxSettings = defaultSettings // defaultLinuxSettingsTemplate;

  userChromeSettings = ''
    #TabsToolbar {
      visibility: collapse;
    }

    #sidebar-header {
      display: none;
    }
  '';
in
{
  programs.firefox = {
    enable = true;

    package = null;

    # Platform-specific profile settings
    profiles =
      if isDarwin then {
        "Home" = {
          id = 0;
          isDefault = false;
          extensions = extensions;
          settings = defaultSettings;
          userChrome = userChromeSettings;
        };
        "Work" = {
          id = 1;
          isDefault = true;
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            granted
            darkreader
            multi-account-containers
            onepassword-password-manager
          ];
          settings = defaultSettings;
          userChrome = userChromeSettings;
        };
      } else {
        "Home" = {
          id = 0;
          isDefault = true;
          extensions = extensions;
          settings = defaultLinuxSettings;
          userChrome = userChromeSettings;
        };
      };
  };
}
