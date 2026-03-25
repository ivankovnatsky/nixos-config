{ config, username, ... }:
{
  services.openssh.enable = true;

  users.users.${username}.openssh.authorizedKeys.keys = [
    config.flags.sshKeys.air
    config.flags.sshKeys.a3
  ];
}
