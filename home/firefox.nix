# Shared Firefox profile settings, reused by machines/a3 and
# machines/Ivans-Mac-mini profile definitions.
{
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

  # Block notification prompts globally (2 = block)
  "permissions.default.desktop-notification" = 2;

  # Block persistent storage prompts globally (2 = block)
  "permissions.default.persistent-storage" = 2;

  # Never offer to save passwords (using Bitwarden instead)
  "signon.rememberSignons" = false;

  # Never show the bookmarks toolbar
  "browser.toolbars.bookmarks.visibility" = "never";

  # Disable picture-in-picture hover toggle on videos
  "media.videocontrols.picture-in-picture.enabled" = false;
  "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
  "media.videocontrols.picture-in-picture.video-toggle.has-used" = false;
}
