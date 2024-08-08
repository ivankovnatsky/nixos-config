{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      # Manage terraform versions
      # https://github.com/tofuutils/tenv/issues/121
      nixpkgs-master.tenv
      tflint
    ];
    file = {
      ".terraform.d/plugin-cache/.keep" = {
        text = ''
          keep
        '';
      };
      ".terraformrc" = {
        # https://developer.hashicorp.com/terraform/cli/config/config-file
        text = ''
          plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
          plugin_cache_may_break_dependency_lock_file = true
          disable_checkpoint = true
        '';
      };
    };
  };
}
