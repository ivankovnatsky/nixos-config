{ pkgs, super, ... }:

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
    file
    killall
    openssl
    whois
    zip
    gcc
    lsof
  ];
}
