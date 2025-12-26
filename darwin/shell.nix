{ config, ... }:
{
  # error:
  #      failed assertions:
  #      - users.users.ivan.shell is set to zsh, but
  #      programs.zsh.enable is not true. this will cause the zsh
  #      shell to lack the basic nix directories in its path and might make
  #      logging in as that user impossible. you can fix it with:
  #      programs.zsh.enable = true;
  programs.zsh.enable = true;
  programs.fish = {
    enable = config.flags.enableFishShell;
    shellInit = ''
      # Add Homebrew path early to prevent "Unknown command: brew" errors
      # This runs before nix-darwin's interactiveShellInit which calls brew shellenv
      if test -d /opt/homebrew/bin
          fish_add_path --prepend /opt/homebrew/bin
      end
      if test -d /usr/local/bin
          fish_add_path --prepend /usr/local/bin
      end
    '';
  };
}
