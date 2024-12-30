{ pkgs, super, ... }:

{
  imports = [
    ../modules/flags
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

  inherit (super) device;
  inherit (super) flags;

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
