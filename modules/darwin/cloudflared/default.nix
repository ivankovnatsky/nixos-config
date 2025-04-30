{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.cloudflared;
in
{
  options.local.services.cloudflared = {
    enable = mkEnableOption "Cloudflare DNS over HTTPS proxy";

    package = mkOption {
      type = types.package;
      default = pkgs.cloudflared;
      defaultText = literalExpression "pkgs.cloudflared";
      description = "The cloudflared package to use.";
    };

    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Listen address for the DNS over HTTPS proxy server";
    };

    port = mkOption {
      type = types.int;
      default = 53;
      description = "Listen port for the DNS over HTTPS proxy server";
    };

    upstreamServers = mkOption {
      type = types.listOf types.str;
      default = [
        "https://1.1.1.1/dns-query"
        "https://8.8.8.8/dns-query"
      ];
      description = "Upstream DNS-over-HTTPS endpoints";
    };

    alwaysKeepRunning = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to restart cloudflared if it stops for any reason";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.daemons.cloudflared = {
      serviceConfig = {
        Label = "org.nixos.cloudflared";
        ProgramArguments = [ 
          "${cfg.package}/bin/cloudflared"
          "proxy-dns"
          "--address"
          cfg.address
          "--port"
          (toString cfg.port)
        ] ++ (lib.concatMap (upstream: ["--upstream" upstream]) cfg.upstreamServers);
        RunAtLoad = true;
        KeepAlive = cfg.alwaysKeepRunning;
        StandardOutPath = "/tmp/log/launchd/cloudflared.log";
        StandardErrorPath = "/tmp/log/launchd/cloudflared.error.log";
      };

      command = let
        startScript = pkgs.writeShellScriptBin "start-cloudflared" ''
          # Create log directory
          mkdir -p /tmp/log/launchd
          chmod 755 /tmp/log/launchd

          echo "Starting cloudflared..."
          exec ${cfg.package}/bin/cloudflared proxy-dns \
            --address ${cfg.address} \
            --port ${toString cfg.port} \
            ${lib.concatMapStringsSep " " (upstream: "--upstream ${upstream}") cfg.upstreamServers}
        '';
      in "${startScript}/bin/start-cloudflared";
    };
  };
}
