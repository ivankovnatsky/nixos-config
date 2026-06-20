{ config, ... }:
{
  flags = {
    enableFishShell = true;
    purpose = "home";
    editor = "nvim";
    editorName = "neovim";
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
          key = "9";
          app = "System Settings";
        }
      ];
    };
  };
}
