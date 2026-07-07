{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  configFile = "${config.home.homeDirectory}/Library/Application Support/rbw/config.json";
  pinentryPackage = if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-tty;
in
{
  programs.rbw.enable = true;

  sops.templates."rbw-config.json".content = builtins.toJSON {
    email = config.sops.placeholder.email;
    lock_timeout = 2419200;
    pinentry = lib.getExe pinentryPackage;
  };

  home.activation.linkRbwConfig =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "sops-nix"
      ]
      ''
        run mkdir -p "$(dirname "${configFile}")"
        run ln -sf ${config.sops.templates."rbw-config.json".path} "${configFile}"
      '';
}
