{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.stubby;
  
  # Override stubby package to remove systemd dependency for Darwin
  stubbyPackage = pkgs.stubby.overrideAttrs (old: {
    buildInputs = with pkgs; [
      getdns
      libyaml
      openssl
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.darwin.Security ];
  });
  
  # Convert settings to YAML for stubby config
  settingsFormat = pkgs.formats.yaml {};
  configFile = settingsFormat.generate "stubby.yml" cfg.settings;
  

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
      type = types.enum [ "emerg" "alert" "crit" "err" "warning" "notice" "info" "debug" ];
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
      example = literalExpression ''
        {
          resolution_type = "GETDNS_RESOLUTION_STUB";
          dns_transport_list = [ "GETDNS_TRANSPORT_TLS" ];
          tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
          tls_query_padding_blocksize = 128;
          round_robin_upstreams = 1;
          idle_timeout = 10000;
          listen_addresses = [ "127.0.0.1@5453" ];
          upstream_recursive_servers = [
            {
              address_data = "45.90.28.0";
              tls_auth_name = "dns.nextdns.io";
            }
            {
              address_data = "45.90.30.0";
              tls_auth_name = "dns.nextdns.io";
            }
          ];
        }
      '';
      description = "Stubby configuration. See https://dnsprivacy.org/dns_privacy_daemon_-_stubby/configuring_stubby/ for details.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Setup directories in activation script
    system.activationScripts.preActivation.text = mkBefore ''
      # Create log directory for stubby
      echo "Setting up stubby directories..."
      mkdir -p /var/log/stubby
      chmod 755 /var/log/stubby
    '';

    launchd.daemons.stubby = {
      command = "${cfg.package}/bin/stubby -C ${configFile} -l ${cfg.logLevel} -v";
      serviceConfig = {
        Label = "org.nixos.stubby";
        RunAtLoad = true;
        KeepAlive = cfg.alwaysKeepRunning;
        AbandonProcessGroup = false;
        StandardErrorPath = "/var/log/stubby/stderr.log";
        StandardOutPath = "/var/log/stubby/stdout.log";
        SoftResourceLimits = {
          NumberOfFiles = 1024;
        };
      };
    };
  };
} 
