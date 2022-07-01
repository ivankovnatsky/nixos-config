{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      # firefox-translations
      bitwarden
      clearurls
      darkreader
      decentraleyes
      duckduckgo-privacy-essentials
      https-everywhere
      multi-account-containers
      onepassword-password-manager
      privacy-badger
      tree-style-tab
      ublock-origin
    ];
  };
}
