{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    homeWorkPath = config.home.homeDirectory;
    hotkeys = {
      terminal = "kitty";
      browser = "Google Chrome";
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
          app = "Google Chrome";
        }
        {
          key = "9";
          app = "System Settings";
        }
      ];
    };
  };
}
