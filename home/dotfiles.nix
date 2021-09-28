{ config, ... }:

{
  home.file = {
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

    ".config/yamllint/config" = {
      text = ''
        document-start: disable
      '';
    };

    ".config/rclone/rclone.conf".source = ../.secrets/config/rclone.conf;

    # under wayland default password store path that `pass` uses points to:
    # ~/.local/share/password-store/
    # aws-vault somehow wants it to be here:
    ".password-store/.gpg-id" = {
      text = ''
        75213+ivankovnatsky@users.noreply.github.com
      '';
    };
  };
}
