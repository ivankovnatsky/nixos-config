{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.stubby;

  logLevels = {
    emerg = 0;
    alert = 1;
    crit = 2;
    err = 3;
    warning = 4;
    notice = 5;
    info = 6;
    debug = 7;
  };

  stubbyPackage = pkgs.stubby.overrideAttrs (_old: {
    buildInputs = with pkgs; [
      getdns
      libyaml
      openssl
    ];
  });

  settingsFormat = pkgs.formats.yaml { };
  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      settingsFormat.generate "stubby.yml" cfg.settings;
in
{
  options.local.services.stubby = {
    enable = mkEnableOption "stubby DNS-over-TLS resolver";

    package = mkOption {
      type = types.package;
      default = stubbyPackage;
      defaultText = literalExpression "pkgs.stubby (with systemd removed)";
      description = "The stubby package to use.";
    };

    logLevel = mkOption {
      type = types.enum [
        "emerg"
        "alert"
        "crit"
        "err"
        "warning"
        "notice"
        "info"
        "debug"
      ];
      default = "info";
      description = "Log level for stubby.";
    };

    alwaysKeepRunning = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to restart stubby if it stops for any reason.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {
        resolution_type = "GETDNS_RESOLUTION_STUB";
        dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
        tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
        tls_query_padding_blocksize = 128;
        idle_timeout = 10000;
        round_robin_upstreams = 1;
        listen_addresses = [ "127.0.0.1@5453" ];
        upstream_recursive_servers = [ ];
      };
      description = "Stubby configuration.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a Stubby configuration file.";
    };

    waitForSecrets = mkOption {
      type = types.bool;
      default = false;
      description = "Wait for sops-nix secrets before starting.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    local.launchd.services.stubby = {
      enable = true;
      keepAlive = cfg.alwaysKeepRunning;
      inherit (cfg) waitForSecrets;
      command = "${cfg.package}/bin/stubby -C ${configFile} -v ${toString logLevels.${cfg.logLevel}}";
      extraServiceConfig = {
        AbandonProcessGroup = false;
        SoftResourceLimits.NumberOfFiles = 1024;
      };
    };
  };
}
