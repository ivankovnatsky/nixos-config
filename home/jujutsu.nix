{ config, ... }:

{
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = config.flags.git.userName;
        email = config.flags.git.userEmail;
      };
      ui = {
        default-command = "log"; # Similar to your git log alias being frequently used
      };
      git = {
        # Similar to your git config
        push-branch-prefix = "refs/heads/";
        push-default = "current";
      };
    };
  };
}
