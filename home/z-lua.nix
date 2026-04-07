{
  config,
  ...
}:

{
  programs.z-lua = {
    enable = true;
    enableAliases = true;
    enableZshIntegration = true;
    enableFishIntegration = config.flags.enableFishShell;
  };
}
