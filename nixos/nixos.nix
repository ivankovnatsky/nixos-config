{ config, pkgs, username, ... }:

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

  users.users.${username} = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/${username}";
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
