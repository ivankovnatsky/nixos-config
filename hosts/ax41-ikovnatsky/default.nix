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
        eks-node-viewer = super.callPackage ../../overlays/eks-node-viewer.nix { };
        granted = super.callPackage ../../overlays/granted.nix { };
        terraform = super.callPackage ../../overlays/hashicorp-generic.nix {
          name = "terraform";
          version = "1.1.7";
          sha256 = "sha256-5K3QkqVP9v69MyXR4MEJyeWQ3Gw4+Lt/ljLk5rzKmdQ=";
          system = "x86_64-linux";
        };
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
    granted
    eks-node-viewer
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
