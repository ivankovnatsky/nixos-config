{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      onepassword-password-manager
      privacy-badger
      clearurls
      decentraleyes
      darkreader
      bitwarden
      multi-account-containers
      ublock-origin
      https-everywhere
      duckduckgo-privacy-essentials
    ];

    profiles = {
      default = {
        isDefault = true;

        settings = {
          "browser.startup.page" = 3;
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
          "media.videocontrols.picture-in-picture.enabled" = false;
          "media.videocontrols.picture-in-picture.video-toggle.has-used" =
            false;
          "permissions.default.desktop-notification" = 2;
          "gfx.webrender.all" = true;
          "extensions.pocket.enabled" = false;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };
    };
  };
}
