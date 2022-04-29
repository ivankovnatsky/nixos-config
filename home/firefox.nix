{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      bitwarden
      clearurls
      darkreader
      decentraleyes
      duckduckgo-privacy-essentials
      https-everywhere
      multi-account-containers
      onepassword-password-manager
      privacy-badger
      tree-style-tab
      ublock-origin
    ];

    profiles = {
      default = {
        isDefault = true;

        settings = {
          "browser.contentblocking.category" = "strict";
          "browser.ctrlTab.recentlyUsedOrder" = true;
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.engagement.ctrlTab.has-used" = true;
          "browser.download.dir" = "/tmp";
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
          "general.smoothScroll" = false;
          "geo.enabled" = false;
          "gfx.webrender.all" = true;
          "media.videocontrols.picture-in-picture.enabled" = false;
          "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
          "media.videocontrols.picture-in-picture.video-toggle.has-used" = false;
          "network.allow-experiments" = false;
          "network.dns.disablePrefetch" = true;
          "permissions.default.desktop-notification" = 2;
          "privacy.donottrackheader.enabled" = true;
          "privacy.donottrackheader.value" = 1;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
          "security.sandbox.content.level" = 3;
        };

        userChrome = ''
          #TabsToolbar {
            visibility: collapse;
          }
        '';
      };
    };
  };
}
