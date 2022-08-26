{ config, pkgs, super, ... }:

{
  imports = [
    ./tmux.nix

    ../modules/secrets.nix
  ];

  programs.rbw = {
    enable = true;
    package = (pkgs.rbw.override { withFzf = true; });

    settings = {
      email = "${config.secrets.email}";
      lock_timeout = 2419200;
      pinentry = pkgs.pinentry;
    };
  };

  secrets = super.secrets;
}
