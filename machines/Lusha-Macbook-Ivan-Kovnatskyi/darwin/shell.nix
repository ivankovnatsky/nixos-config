{ config, ... }:
{
  # error:
  #      Failed assertions:
  #      - users.users.ivan.shell is set to zsh, but
  #      programs.zsh.enable is not true. This will cause the zsh
  #      shell to lack the basic nix directories in its PATH and might make
  #      logging in as that user impossible. You can fix it with:
  #      programs.zsh.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = config.flags.enableFishShell;
}
