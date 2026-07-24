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

  rbwPackage = pkgs.rbw.override { withFzf = true; };

  syncInterval = 60 * 60; # 1 hour

  syncScript = pkgs.writeShellScript "rbw-sync" ''
    # Only sync when the agent is already unlocked; otherwise a background
    # job would trigger a pinentry prompt (or just fail).
    if ${lib.getExe rbwPackage} unlocked 2>/dev/null; then
      exec ${lib.getExe rbwPackage} sync
    fi
  '';
in
{
  programs.rbw = {
    enable = true;
    package = rbwPackage;
  };

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

  local.launchd.services.rbw-sync = lib.mkIf isDarwin {
    enable = true;
    keepAlive = false;
    runAtLoad = true;
    command = "${syncScript}";

    extraServiceConfig = {
      StartInterval = syncInterval;
    };
  };

  systemd.user.services.rbw-sync = lib.mkIf (!isDarwin) {
    Unit = {
      Description = "Sync rbw vault";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}";
    };
  };

  systemd.user.timers.rbw-sync = lib.mkIf (!isDarwin) {
    Unit.Description = "Run rbw sync periodically";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "${toString syncInterval}s";
      Unit = "rbw-sync.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
