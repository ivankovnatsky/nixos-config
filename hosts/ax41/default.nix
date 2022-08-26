{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix

    ../../modules/secrets.nix
  ];

  time.timeZone = "Europe/Helsinki";

  networking.hostName = "ax41";

  environment.systemPackages = with pkgs; [
    git-crypt
    git
    neovim
    tmux
    syncthing
  ];

  users.users.ivan.openssh.authorizedKeys.keys = [
    "${config.secrets.sshPublicKey}"
  ];

  # Syncthing
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
