{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      privacy-badger
      keepassxc-browser
      clearurls
      decentraleyes
      xbrowsersync
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
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
          "media.videocontrols.picture-in-picture.enabled" = false;
          "media.videocontrols.picture-in-picture.video-toggle.has-used" =
            false;
          "gfx.webrender.all" = true;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };
    };
  };
}
