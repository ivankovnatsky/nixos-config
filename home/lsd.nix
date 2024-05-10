{ config, pkgs, ... }:

{
  # Why lsd and not eza? Because lsd accepts arguments like `-t` which I could
  # use from to time and it looks like more compatible to traditional `ls`
  # command.
  # https://github.com/lsd-rs/lsd
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/lsd.nix
  home.packages = with pkgs; [ lsd ];
  home.file = {
    ".config/lsd/config.yaml".text = ''
      color:
        theme: custom
    '';
    ".config/lsd/colors.yaml".text = ''
      user: ${if config.flags.darkMode then "230" else "100"}
      group: 187
      permission:
        read: dark_green
        write: dark_yellow
        exec: dark_red
        exec-sticky: 5
        no-access: 245
        octal: 6
        acl: dark_cyan
        context: cyan
      date:
        hour-old: 40
        day-old: 42
        older: 36
      size:
        none: ${if config.flags.darkMode then "245" else "190"}
        small: ${if config.flags.darkMode then "229" else "185"}
        medium: ${if config.flags.darkMode then "216" else "180"}
        large: 172
      inode:
        valid: 13
        invalid: 245
      links:
        valid: 13
        invalid: 245
      tree-edge: 245
      git-status:
        default: 245
        unmodified: 245
        ignored: 245
        new-in-index: dark_green
        new-in-workdir: dark_green
        typechange: dark_yellow
        deleted: dark_red
        renamed: dark_green
        modified: dark_yellow
        conflicted: dark_red
    '';
  };
}
