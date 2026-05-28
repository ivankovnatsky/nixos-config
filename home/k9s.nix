{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  k9sConfigPath = if isDarwin then "Library/Application Support" else ".config";
in
{
  home.packages = with pkgs; [ k9s ];
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
  '';
}
