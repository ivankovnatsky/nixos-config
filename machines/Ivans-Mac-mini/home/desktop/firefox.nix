{ ... }:
{
  programs.firefox = {
    enable = true;
    # Installed via Homebrew cask (firefox@developer-edition).
    package = null;

    profiles."default" = {
      id = 0;
      isDefault = true;
      settings = {
        # Enable vertical tabs
        "sidebar.verticalTabs" = true;

        # Place sidebar on the left
        "sidebar.position_start" = true;

        # Restore previous session (tabs and windows)
        "browser.startup.page" = 3;

        # Enable Ctrl+Tab to cycle through recent tabs
        "browser.ctrlTab.recentlyUsedOrder" = true;
        "browser.ctrlTab.sortByRecentlyUsed" = true;

        # Never suggest translating pages
        "browser.translations.automaticallyPopup" = false;

        # Block geolocation prompts globally (2 = block)
        "permissions.default.geo" = 2;
      };
    };
  };
}
