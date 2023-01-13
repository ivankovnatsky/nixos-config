{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix

    ../../modules/secrets.nix
    ../../modules/falcon-sensor.nix
  ];

  time.timeZone = "Europe/Berlin";

  nixpkgs.overlays = [
    (
      self: super: {
        falcon-sensor = super.callPackage ../../overlays/falcon-sensor.nix { };
        pv-migrate = super.callPackage ../../overlays/pv-migrate.nix { };
      }
    )
  ];

  environment.systemPackages = with pkgs; [
    git-crypt
    git
    neovim
    tmux
    syncthing
    falcon-sensor
    pv-migrate
  ];

  custom.falcon.enable = true;
  services.fail2ban.enable = true;

  users.users.ivan.openssh.authorizedKeys.keys = [
    "${config.secrets.sshPublicKey}"
  ];

  # Syncthing
  networking.firewall.allowedTCPPorts = [ 8384 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
