{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.default.extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      # firefox-translations
      # granted-containers
      bitwarden
      clearurls
      darkreader
      decentraleyes
      duckduckgo-privacy-essentials
      # https-everywhere
      multi-account-containers
      onepassword-password-manager
      privacy-badger
      # tree-style-tab
      ublock-origin
    ];
  };
}
