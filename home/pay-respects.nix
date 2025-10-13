{ config, ... }:
{
  programs.pay-respects = {
    enable = true;
    enableFishIntegration = config.flags.enableFishShell;
  };
}
