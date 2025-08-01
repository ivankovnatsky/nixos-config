{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = true;
    homeWorkPath = config.home.homeDirectory;
    hotkeys = {
      terminal = "Ghostty";
      browser = "Firefox Developer Edition";
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
          app = "Slack";
        }
        {
          key = "9";
          app = "System Settings";
        }
      ];
    };
    apps = {
      vscode.enable = false;
    };
  };
}
