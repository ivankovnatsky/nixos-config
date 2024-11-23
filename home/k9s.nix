{ config, pkgs, ... }:

let inherit (pkgs.stdenv.targetPlatform) isDarwin;
  k9sConfigPath = if isDarwin then "Library/Application Support" else ".config";
in
{
  home.packages = with pkgs; [ k9s ];
  # https://k9scli.io/topics/skins/
  # https://github.com/derailed/k9s/tree/master/skins
  home.file."${k9sConfigPath}/k9s/skins/transparent.yaml".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/derailed/k9s/master/skins/transparent.yaml";
    sha256 = "sha256-4+tCRcI5fsSwqqhnNEZiD6LAc6ZW/AaP7KZ0003/XSE=";
  };
  home.file."${k9sConfigPath}/k9s/config.yaml".text = ''
    k9s:
      liveViewAutoRefresh: false
      refreshRate: 2
      maxConnRetry: 5
      readOnly: false
      ui:
        enableMouse: false
        headless: true
        logoless: true
        crumbsless: true
        noIcons: true
        # Uses skin located in your $XDG_CONFIG_HOME/skins/
        ${if config.flags.darkMode then "" else "skin: transparent"}
  '';
}
