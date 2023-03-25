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

  home.packages = with pkgs; [
    _1password
    awscli2
    file
    killall
    openssl
    whois
    zip
  ];
}
