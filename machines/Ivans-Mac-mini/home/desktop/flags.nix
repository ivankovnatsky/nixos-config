{ config, ... }:
{
  device = {
    name = "mac";
    type = "server";
  };
  inventory.machineBindAddress = "0.0.0.0";
  inventory.machineLocalAddress = "127.0.0.1";
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "nvim";
    hotkeys = {
      terminal = "kitty";
      browser = "Safari";
      shortcuts = [
        {
          key = "1";
          app = "Finder";
        }
        {
          key = "2";
          app = config.flags.hotkeys.terminal;
        }
        {
          key = "3";
          app = config.flags.hotkeys.browser;
        }
        {
          key = "4";
          app = "Cursor";
        }
        {
          key = "9";
          app = "System Settings";
        }
      ];
    };
  };
}
