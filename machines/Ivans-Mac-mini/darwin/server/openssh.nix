{ config, username, ... }:
{
  services.openssh.enable = true;

  users.users.${username}.openssh.authorizedKeys.keys = [
    config.inventory.sshKeys.air
    config.inventory.sshKeys.a3
  ];
}
