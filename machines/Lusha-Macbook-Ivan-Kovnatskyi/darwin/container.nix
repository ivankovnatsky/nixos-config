{ pkgs, ... }:

let
  bin = "${pkgs.nixpkgs-darwin-master-container.container}/bin/container";
  containerStarter = pkgs.writeShellScript "container-starter" ''
    ${bin} system start --enable-kernel-install
  '';
in
{
  environment.systemPackages = [ pkgs.nixpkgs-darwin-master-container.container ];

  local.launchd.services.container = {
    enable = true;
    type = "user-agent";
    command = "${containerStarter}";
  };
}
