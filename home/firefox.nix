{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      privacy-badger
      clearurls
      decentraleyes
      xbrowsersync
      bitwarden
      ublock-origin
      https-everywhere
      duckduckgo-privacy-essentials
    ];

    profiles = {
      default = {
        isDefault = true;

        settings = {
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "gfx.webrender.all" = true;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };

      work = {
        isDefault = false;
        id = 1;

        settings = {
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "gfx.webrender.all" = true;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };
    };
  };
}
