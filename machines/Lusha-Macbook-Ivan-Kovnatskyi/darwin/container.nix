{ pkgs, ... }:

let
  bin = "${pkgs.nixpkgs-darwin-master-container.container}/bin/container";
  containerStarter = pkgs.writeShellScript "container-starter" ''
    ${bin} system kernel set --recommended
    ${bin} system start
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
