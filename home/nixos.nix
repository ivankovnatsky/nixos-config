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

  device = super.device;
  flags = super.flags;

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
