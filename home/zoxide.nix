{
  config,
  ...
}:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = config.flags.enableFishShell;
  };
}
