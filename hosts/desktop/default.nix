{ config, lib, pkgs, options, ... }:

{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix

    ../../system/opengl-intel.nix

    ../../modules/secrets.nix
  ];

  networking.hostName = "desktop";

  device = {
    type = "desktop";
  };

  hardware.cpu.intel.updateMicrocode = true;

  services.openssh.enable = true;
  users.users.ivan.openssh.authorizedKeys.keys = [
    "${config.secrets.sshPublicKey}"
  ];

  system.stateVersion = "22.11";
}
