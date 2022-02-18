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
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "browser.fullscreen.autohide" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "never";
          "extensions.pocket.enabled" = false;
          "geo.enabled" = false;
          "gfx.webrender.all" = true;
          "media.videocontrols.picture-in-picture.enabled" = false;
          "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
          "media.videocontrols.picture-in-picture.video-toggle.has-used" = false;
          "network.allow-experiments" = false;
          "permissions.default.desktop-notification" = 2;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };
    };
  };
}
