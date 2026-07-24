{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  configFile =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/rbw/config.json"
    else
      "${config.xdg.configHome}/rbw/config.json";
  pinentryPackage = pkgs.pinentry-tty;
in
{
  programs.rbw = {
    enable = true;
    package = pkgs.rbw.override { withFzf = true; };
  };

  sops.templates."rbw-config.json".content = builtins.toJSON {
    email = config.sops.placeholder.email;
    lock_timeout = 2419200;
    # The rbw agent background-syncs on its own while running (upstream
    # default is also 3600); no external launchd/systemd job is needed.
    sync_interval = 60 * 60; # 1 hour
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
