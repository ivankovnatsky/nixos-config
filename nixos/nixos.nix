{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./packages.nix
  ];

  security = {
    rtkit.enable = true;
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
