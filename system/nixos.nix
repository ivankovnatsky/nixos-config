{ pkgs, ... }:

{
  imports = [
    ./packages.nix
  ];

  security = {
    rtkit.enable = true;
    sudo.configFile = ''
      Defaults timestamp_timeout=240
    '';
  };

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };
}
