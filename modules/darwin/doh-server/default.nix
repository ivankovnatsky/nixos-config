{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.doh-server;
  toml = pkgs.formats.toml { };
in
{
  options.local.services.doh-server = {
    enable = mkEnableOption "DNS-over-HTTPS server";

    package = mkOption {
      type = types.package;
      default = pkgs.dns-over-https;
      defaultText = literalExpression "pkgs.dns-over-https";
      description = "The dns-over-https package to use.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = toml.type;
        options = {
          listen = mkOption {
            type = types.listOf types.str;
            default = [ "127.0.0.1:8053" ];
            example = [ ":443" ];
            description = "HTTP listen address and port";
          };

          path = mkOption {
            type = types.str;
            default = "/dns-query";
            example = "/dns-query";
            description = "HTTP path for resolve application";
          };

          upstream = mkOption {
            type = types.listOf types.str;
            default = [ "udp:127.0.0.1:53" ];
            example = [ "udp:127.0.0.1:53" ];
            description = ''
              Upstream DNS resolver.
              If multiple servers are specified, a random one will be chosen each time.
              You can use "udp", "tcp" or "tcp-tls" for the type prefix.
            '';
          };

          timeout = mkOption {
            type = types.int;
            default = 10;
            example = 15;
            description = "Upstream timeout in seconds";
          };

          tries = mkOption {
            type = types.int;
            default = 3;
            example = 5;
            description = "Number of tries if upstream DNS fails";
          };

          verbose = mkOption {
            type = types.bool;
            default = false;
            example = true;
            description = "Enable logging";
          };

          log_guessed_client_ip = mkOption {
            type = types.bool;
            default = false;
            example = true;
            description = "Enable logging of client IP from proxy headers";
          };
        };
      };
      default = { };
      example = {
        listen = [ ":8053" ];
        upstream = [ "udp:127.0.0.1:53" ];
      };
      description = "Configuration for doh-server in TOML format";
    };

    alwaysKeepRunning = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to restart doh-server if it stops for any reason";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.doh-server = {
      command = let
        configFile = toml.generate "doh-server.conf" cfg.settings;
        startScript = pkgs.writeShellScriptBin "start-doh-server" ''
          # Create log directory
          mkdir -p /tmp/log/doh-server
          chmod 755 /tmp/log/doh-server

          echo "Starting doh-server..."
          exec ${cfg.package}/bin/doh-server -conf ${configFile}
        '';
      in "${startScript}/bin/start-doh-server";

      serviceConfig = {
        Label = "org.nixos.doh-server";
        RunAtLoad = true;
        KeepAlive = cfg.alwaysKeepRunning;
        AbandonProcessGroup = false;
        StandardOutPath = "/tmp/log/launchd/doh-server.log";
        StandardErrorPath = "/tmp/log/launchd/doh-server.error.log";
      };
    };
  };
}
