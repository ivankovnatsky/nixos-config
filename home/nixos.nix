{ config, pkgs, super, ... }:

let
  editorName = "nvim";

in
{
  imports = [
    ../modules/default.nix
  ];

  services.syncthing = {
    enable = true;
    extraOptions = [
      "--gui-address=http://0.0.0.0:8384"
    ];
  };

  services = {
    gpg-agent.enable = true;
  };

  device = super.device;
  variables = super.variables;
}
