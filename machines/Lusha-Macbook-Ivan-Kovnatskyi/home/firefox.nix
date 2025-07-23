{ config, ... }:

let
  firefoxProfile = "1pnq61kq.dev-edition-default";
in
{
  home.file = {
    # Firefox Developer Edition user.js configuration
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/user.js".text = ''
      // Disable extension signature requirement for Tweety
      user_pref("xpinstall.signatures.required", false);
      
      // Enable vertical tabs
      user_pref("sidebar.verticalTabs", true);
      
      // Restore previous session (tabs and windows)
      user_pref("browser.startup.page", 3);
      
      // Enable Ctrl+Tab to cycle through recent tabs
      user_pref("browser.ctrlTab.recentlyUsedOrder", true);
    '';

    # Install Tweety extension automatically
    "Library/Application Support/Firefox/Profiles/${firefoxProfile}/extensions/tweety@pomdtr.me.xpi" = {
      source = "/opt/homebrew/share/tweety/extensions/firefox.zip";
    };
  };
}
