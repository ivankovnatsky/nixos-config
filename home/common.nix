{
  config,
  pkgs,
  super,
  ...
}:

{
  imports = [
    ../modules/secrets
    ./tmux.nix
  ];

  programs.rbw = {
    enable = true;

    settings = {
      email = "${config.secrets.email}";
      lock_timeout = 2419200;
      inherit (pkgs) pinentry;
    };
  };

  inherit (super) secrets;
}
