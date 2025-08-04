{ config, pkgs, ... }:

{
  imports = [
    ./packages.nix
  ];

  security = {
    rtkit.enable = true;
    sudo.configFile = ''
      Defaults timestamp_timeout=720
    '';
  };

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = if config.flags.enableFishShell then pkgs.fish else pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };
}
