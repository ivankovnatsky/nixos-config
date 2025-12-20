{ config, pkgs, ... }:

let
  hostName = config.networking.hostName;
  dataDir = "${config.flags.miniStoragePath}/.promtail";
  lokiUrl = "http://${config.flags.miniIp}:3100/loki/api/v1/push";

  promtailConfig = pkgs.writeText "promtail-config.yaml" (builtins.toJSON {
    server = {
      http_listen_address = config.flags.miniIp;
      http_listen_port = 9080;
      grpc_listen_port = 9097;
    };
    positions = {
      filename = "${dataDir}/positions.yaml";
    };
    clients = [
      {
        url = lokiUrl;
        batchwait = "1s";
        batchsize = 1048576;
        backoff_config = {
          min_period = "500ms";
          max_period = "5m";
          max_retries = 10;
        };
      }
    ];
    limits_config = {
      readline_rate_enabled = true;
      readline_rate = 100;
      readline_burst = 200;
    };
    scrape_configs = [
      {
        job_name = "launchd-logs";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "launchd";
              host = hostName;
              __path__ = "/tmp/agents/log/launchd/*.log";
            };
          }
        ];
      }
      {
        job_name = "launchd-errors";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "launchd-errors";
              host = hostName;
              __path__ = "/tmp/agents/log/launchd/*.error.log";
            };
          }
        ];
      }
      {
        job_name = "daemon-logs";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "daemon";
              host = hostName;
              __path__ = "/tmp/log/launchd/*.log";
            };
          }
        ];
      }
      {
        job_name = "system-logs";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "system";
              host = hostName;
              __path__ = "/var/log/*.log";
            };
          }
        ];
      }
      {
        job_name = "user-logs";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "macos-user";
              host = hostName;
              __path__ = "/Users/*/Library/Logs/**/*.log";
            };
          }
        ];
      }
      {
        job_name = "application-logs";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "macos-applications";
              host = hostName;
              __path__ = "/Library/Logs/**/*.log";
            };
          }
        ];
      }
      {
        job_name = "diagnostic-reports";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "macos-diagnostics";
              host = hostName;
              __path__ = "/Library/Logs/DiagnosticReports/**/*.log";
            };
          }
        ];
      }
      {
        job_name = "user-diagnostic-reports";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "macos-user-diagnostics";
              host = hostName;
              __path__ = "/Users/*/Library/Logs/DiagnosticReports/**/*.log";
            };
          }
        ];
      }
    ];
  });
in
{
  local.launchd.services.promtail = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command = ''
      ${pkgs.promtail}/bin/promtail \
        -config.file=${promtailConfig} \
        -config.expand-env=true
    '';
  };
}
