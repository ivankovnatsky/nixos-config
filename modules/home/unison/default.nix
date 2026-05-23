{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.unison;

  syncType = lib.types.submodule {
    options = {
      pathA = lib.mkOption {
        type = lib.types.str;
        description = "First root directory";
      };
      pathB = lib.mkOption {
        type = lib.types.str;
        description = "Second root directory";
      };
      ignore = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "Path .git"
          "Name .DS_Store"
        ];
        description = "Unison ignore patterns";
      };
      interval = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "Sync interval in seconds";
      };
      waitForPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to wait for before syncing";
      };
    };
  };

  mkProfile = _name: sync: ''
    root = ${sync.pathA}
    root = ${sync.pathB}

    batch = true
    perms = 0
    dontchmod = true
    xattrs = false

    ${lib.concatMapStringsSep "\n" (i: "ignore = ${i}") sync.ignore}
  '';

  mkLaunchdService = name: sync: {
    enable = true;
    command = "${pkgs.unison}/bin/unison -batch ${name}";
    inherit (sync) waitForPath;
    keepAlive = false;
    runAtLoad = false;
    extraServiceConfig = {
      StartInterval = sync.interval;
    };
  };

  mkSystemdService = name: _sync: {
    Unit = {
      Description = "Unison sync (${name})";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.unison}/bin/unison -batch ${name}";
    };
  };

  mkSystemdTimer = name: sync: {
    Unit = {
      Description = "Unison sync (${name}) timer";
    };
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "${toString sync.interval}s";
      Unit = "unison-${name}.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
in
{
  options.local.unison.syncs = lib.mkOption {
    type = lib.types.attrsOf syncType;
    default = { };
    description = "Unison sync pairs";
  };

  config = lib.mkIf (cfg.syncs != { }) {
    home.packages = [ pkgs.unison ];

    home.file = lib.mapAttrs' (
      name: sync: lib.nameValuePair ".unison/${name}.prf" { text = mkProfile name sync; }
    ) cfg.syncs;

    local.launchd.services = lib.mkIf pkgs.stdenv.isDarwin (
      lib.mapAttrs' (name: sync: lib.nameValuePair "unison-${name}" (mkLaunchdService name sync)) cfg.syncs
    );

    systemd.user.services = lib.mkIf pkgs.stdenv.isLinux (
      lib.mapAttrs' (name: sync: lib.nameValuePair "unison-${name}" (mkSystemdService name sync)) cfg.syncs
    );

    systemd.user.timers = lib.mkIf pkgs.stdenv.isLinux (
      lib.mapAttrs' (name: sync: lib.nameValuePair "unison-${name}" (mkSystemdTimer name sync)) cfg.syncs
    );
  };
}
