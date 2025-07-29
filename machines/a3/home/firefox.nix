{ config, pkgs, ... }:

{
  home.packages = [ pkgs.tweety ];
  
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;
    profiles."dev-edition-default" = {
      settings = {
        # Disable extension signature requirement for Tweety
        "xpinstall.signatures.required" = false;
        
        # Enable vertical tabs
        "sidebar.verticalTabs" = true;
        
        # Restore previous session (tabs and windows)
        "browser.startup.page" = 3;
        
        # Enable Ctrl+Tab to cycle through recent tabs
        "browser.ctrlTab.recentlyUsedOrder" = true;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
      };
      
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        darkreader
        bitwarden
      ];
    };
  };
  
  home.file = {
    # Install Tweety extension manually
    ".mozilla/firefox/dev-edition-default/extensions/tweety@pomdtr.me.xpi" = {
      source = "${pkgs.tweety}/share/extensions/firefox.zip";
    };
  };
}
