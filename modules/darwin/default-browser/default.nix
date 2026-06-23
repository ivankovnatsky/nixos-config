{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.defaultBrowser;
in
{
  options.local.defaultBrowser = {
    enable = mkEnableOption "set default browser during activation";

    browser = mkOption {
      type = types.enum [
        "firefoxdeveloperedition"
        "safari"
      ];
      default = "safari";
      description = "Browser to set as default";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      ${pkgs.defaultbrowser}/bin/defaultbrowser ${cfg.browser}
    '';
  };
}
