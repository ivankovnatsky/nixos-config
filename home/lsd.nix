{ pkgs, ... }:

{
  # Why lsd and not eza? Because lsd accepts arguments like `-t` which I could
  # use from to time and it looks like more compatible to traditional `ls`
  # command.
  # https://github.com/lsd-rs/lsd
  # https://github.com/lsd-rs/lsd/blob/master/README.md#config-file-content
  home.packages = with pkgs; [ lsd ];
  home.file = {
    ".config/lsd/config.yaml".text = ''
      color:
        theme: custom
      icons:
        when: always
      sorting:
        dir-grouping: first
    '';
    ".config/lsd/colors.yaml".text = ''
      user: "230"
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
        none: "245"
        small: "229"
        medium: "216"
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
