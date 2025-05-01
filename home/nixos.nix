{ pkgs, super, ... }:

{
  imports = [
    ../modules/flags
  ];

  services.syncthing = {
    enable = true;
    extraOptions = [
      "--gui-address=http://127.0.0.1:8384"
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
