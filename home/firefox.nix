{
  programs.firefox = {
    enable = true;

    profiles = {
      default = {
        isDefault = true;

        settings = {
          "gfx.webrender.all" = true;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };

      work = {
        isDefault = false;
        id = 1;

        settings = {
          "gfx.webrender.all" = true;
          "widget.wayland-dmabuf-vaapi.enabled" = true;
        };
      };
    };
  };
}
