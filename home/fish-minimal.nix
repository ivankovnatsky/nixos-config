{
  config,
  ...
}:

{
  programs.fish = {
    enable = config.flags.enableFishShell;
  };
}
