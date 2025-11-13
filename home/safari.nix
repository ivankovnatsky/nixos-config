{ ... }:

{
  targets.darwin.defaults = {
    "com.apple.Safari" = {
      ShowFullURLInSmartSearchField = true;
      ShowStandaloneTabBar = true; # false enables compact tabs
      AutoOpenSafeDownloads = false; # Disable automatic downloads
      AlwaysPromptForDownloadLocation = true; # Ask where to save downloads
      # Enable Web Inspector and developer features
      DeveloperPreferences = 836;
    };

    # Additional Safari settings for download location prompt
    "com.apple.Safari.SandboxBroker" = {
      AlwaysPromptForDownloadFolder = true;
    };
  };
}
