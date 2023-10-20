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
      # To disable all those tree shenanigans:
      # https://github.com/piroor/treestyletab/issues/1544#issuecomment-522902490
      # tree-style-tab
      ublock-origin
    ];
  };
}
