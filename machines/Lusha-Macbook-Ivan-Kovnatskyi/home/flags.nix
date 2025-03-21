{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "work";
    editor = "nvim";
    darkMode = true;
    hotkeys = {
      terminal = "Ghostty";
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
          app = "Vivaldi";
        }
        {
          key = "5";
          app = "Google Chrome";
        }
        {
          key = "6";
          app = "Floorp";
        }
        {
          key = "7";
          app = "Slack";
        }
        {
          key = "9";
          app = "System Settings";
        }
      ];
    };
    apps = {
      vscode.enable = true;
    };
  };
}
