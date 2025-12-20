{ config, pkgs, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.prometheus";

  prometheusConfig = pkgs.writeText "prometheus.yml" ''
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
              - ${config.flags.miniIp}:9090

      - job_name: beszel-hub
        static_configs:
          - targets:
              - ${config.flags.miniIp}:8091

      - job_name: loki
        static_configs:
          - targets:
              - ${config.flags.miniIp}:3100

      - job_name: promtail
        static_configs:
          - targets:
              - ${config.flags.miniIp}:9080
  '';
in
{
  local.launchd.services.prometheus = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    command = ''
      ${pkgs.prometheus}/bin/prometheus \
        --config.file=${prometheusConfig} \
        --storage.tsdb.path=${dataDir} \
        --web.listen-address=${config.flags.miniIp}:9090 \
        --web.enable-lifecycle
    '';
  };
}
