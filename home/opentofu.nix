{ ... }:

{
  home.file = {
    ".opentofu/plugin-cache/.keep" = {
      text = ''
        keep
      '';
    };
    ".tofurc" = {
      # https://opentofu.org/docs/cli/config/config-file/
      text = ''
        plugin_cache_dir = "$HOME/.opentofu/plugin-cache"
        plugin_cache_may_break_dependency_lock_file = true
        disable_checkpoint = true
      '';
    };
  };
}
