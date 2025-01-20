{ config, ... }:
{
  programs.thefuck = {
    enable = true;
    enableFishIntegration = config.flags.enableFishShell;
  };
}
