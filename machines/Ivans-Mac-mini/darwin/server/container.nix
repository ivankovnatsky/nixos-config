{ pkgs, ... }:

let
  containerStarter = pkgs.writeShellScript "container-starter" ''
    ${pkgs.container}/bin/container system start
  '';
in
{
  environment.systemPackages = [ pkgs.container ];

  local.launchd.services.container = {
    enable = true;
    type = "daemon";
    command = "${containerStarter}";
  };
}
