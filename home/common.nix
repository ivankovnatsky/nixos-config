{ config, pkgs, super, ... }:

{
  imports = [
    ./tmux.nix

    ../modules/secrets
  ];

  programs.rbw = {
    enable = true;

    settings = {
      email = "${config.secrets.email}";
      lock_timeout = 2419200;
      pinentry = pkgs.pinentry;
    };
  };

  secrets = super.secrets;
}
