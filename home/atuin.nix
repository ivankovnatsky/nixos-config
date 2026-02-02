{
  config,
  pkgs,
  ...
}:

{
  # https://github.com/atuinsh/atuin/commit/1ce88c9d17c6dd66d387b2dfd2544a527a262f3e.
  programs.atuin = {
    enable = true;
    package = pkgs.atuin;
    enableZshIntegration = true;
    enableFishIntegration = config.flags.enableFishShell;
    flags = [ "--disable-up-arrow" ];
    settings = {
      update_check = false;
      style = "compact";
      inline_height = 25;
      # history_filter = [ ];
    };
  };
}
