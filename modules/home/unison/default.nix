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
    xattrs = false

    ${lib.concatMapStringsSep "\n" (i: "ignore = ${i}") sync.ignore}
  '';

  mkService = name: sync: {
    enable = true;
    command = "${pkgs.unison}/bin/unison -batch ${name}";
    inherit (sync) waitForPath;
    keepAlive = false;
    runAtLoad = false;
    extraServiceConfig = {
      StartInterval = sync.interval;
    };
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

    local.launchd.services = lib.mapAttrs' (
      name: sync: lib.nameValuePair "unison-${name}" (mkService name sync)
    ) cfg.syncs;
  };
}
