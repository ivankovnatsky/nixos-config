{ pkgs, ... }:

let inherit (pkgs.stdenv.targetPlatform) isDarwin;
  k9sConfigPath = if isDarwin then "Library/Application Support" else ".config";

in
{
  # Config for k9s
  # https://k9scli.io/topics/skins/
  # https://github.com/derailed/k9s/tree/master/skins
  home.file."${k9sConfigPath}/k9s/skins/transparent.yaml".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/derailed/k9s/master/skins/transparent.yaml";
    sha256 = "sha256-4+tCRcI5fsSwqqhnNEZiD6LAc6ZW/AaP7KZ0003/XSE=";
  };
  home.file."${k9sConfigPath}".text = ''
    k9s:
      liveViewAutoRefresh: false
      refreshRate: 2
      maxConnRetry: 5
      enableMouse: false
      headless: true
      logoless: true
      crumbsless: true
      readOnly: false
      noExitOnCtrlC: false
      noIcons: true
      skipLatestRevCheck: true
      ui:
        skin: transparent
      logger:
        tail: 100
        buffer: 5000
        sinceSeconds: 60
        fullScreenLogs: false
        textWrap: false
        showTime: false
  '';
}
