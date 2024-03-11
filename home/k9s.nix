{ pkgs, ... }:

let inherit (pkgs.stdenv.targetPlatform) isDarwin;
  k9sConfigPath = if isDarwin then "Library/Application Support/k9s/config.yml" else ".config/k9s/config.yml";

in
{
  # Config for k9s
  # https://k9scli.io/topics/skins/
  # https://github.com/derailed/k9s/tree/master/skins
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
      logger:
        tail: 100
        buffer: 5000
        sinceSeconds: 60
        fullScreenLogs: false
        textWrap: false
        showTime: false
  '';
}
