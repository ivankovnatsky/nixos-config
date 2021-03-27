{
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
