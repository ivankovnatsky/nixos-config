{ pkgs, ... }:

let
  bin = "${pkgs.container}/bin/container";
  containerStarter = pkgs.writeShellScript "container-starter" ''
    ${bin} system start --enable-kernel-install
  '';
in
{
  environment.systemPackages = [ pkgs.container ];

  local.launchd.services.container = {
    enable = true;
    type = "user-agent";
    command = "${containerStarter}";
  };
}
