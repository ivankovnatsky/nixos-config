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
        default-command = "log";
      };
      git = {
        push-branch-prefix = "refs/heads/";
        push-default = "current";
      };
      signing = {
        sign-all = true;
        backend = "gpg";
      };
      "template-aliases" = {
        "format_timestamp(timestamp)" = "timestamp.ago()";
      };
    };
  };
}
