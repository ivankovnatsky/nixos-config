{
  services = {
    gpg-agent.enable = true;

    gammastep = {
      enable = true;
      provider = "geoclue2";

      temperature = {
        day = 5500;
        night = 3700;
      };
    };
  };

  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
      '';
    };

    ".terraform.d/plugin-cache/.keep" = {
      text = ''
        keep
      '';
    };

    ".terraformrc" = {
      text = ''
        plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
      '';
    };
  };
}
