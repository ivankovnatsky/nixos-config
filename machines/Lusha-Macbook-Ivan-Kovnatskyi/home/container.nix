{ pkgs, ... }:

let
  bin = "${pkgs.container}/bin/container";
  containerStarter = pkgs.writeShellScript "container-starter" ''
    ${bin} system start --enable-kernel-install
  '';
in
{
  home.packages = [ pkgs.container ];

  local.launchd.services.container = {
    enable = true;
    command = "${containerStarter}";
  };
}
