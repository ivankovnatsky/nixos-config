{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    yamllint
  ];

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

    # under wayland default password store path that `pass` uses points to:
    # ~/.local/share/password-store/
    # aws-vault somehow wants it to be here:
    ".password-store/.gpg-id" = {
      text = ''
        75213+ivankovnatsky@users.noreply.github.com
      '';
    };

    ".config/clipcat/clipcatd.toml" = {
      text = ''
        daemonize = true          # run as a traditional UNIX daemon
        max_history = 50          # max clip history limit
        log_level = 'INFO'        # log level

        [monitor]
        load_current = true       # load current clipboard content at startup
        enable_clipboard = true   # watch X11 clipboard
        enable_primary = true     # watch X11 primary clipboard

        [grpc]
        host = '127.0.0.1'        # host address for gRPC
        port = 45045              # port number for gRPC
      '';
    };

    ".config/clipcat/clipcat-menu.toml" = {
      text = ''
        server_host = '127.0.0.1' # host address of clipcat gRPC server
        server_port = 45045       # port number of clipcat gRPC server
        finder = 'fzf'            # the default finder to invoke when no "--finder=<finder>" option provided
      '';
    };
  };
}
