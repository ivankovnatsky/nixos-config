{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "nvim";
    darkMode = true;
    homeWorkPath = config.flags.externalStoragePath;
    hotkeys = {
      terminal = "Terminal";
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
    obsidian.vaultPaths = [
      "Sources/github.com/ivankovnatsky/nixos-config"
      "Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes"
    ];
    apps = {
      vscode.enable = false;
    };
  };
}
