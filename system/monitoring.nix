{ pkgs, ... }:

{
  services = {
    grafana = {
      enable = false;

      provision = {
        enable = true;

        datasources = [{
          type = "prometheus";
          name = "Prometheus";
          isDefault = true;
          url = "http://localhost:9090";
        }];

        dashboards = [
          {
            name = "Node Exporter Full";
            options.path = pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/rfrail3/grafana-dashboards/3072e63640a8b026e2f62da5d2d53fb3dcfb0686/prometheus/node-exporter-full.json";
              sha256 = "sha256-FmkCRS9E5RSHcSZvCIH2iKH773G6DQTTJQYUwnmw+BA=";
            };
          }

          {
            name = "Node Exporter Battery";
            options.path = pkgs.fetchurl {
              url = "https://gist.githubusercontent.com/ivankovnatsky/998ab1ba6a437784c4f3517daf1148aa/raw/57197452ac707da0e86ca37469b456390e068018/battery-dashboard.json";
              sha256 = "sha256-8d1QytmZH++k11qedgbpWEl2xAPiTAn9re1t+yTtcog=";
            };
          }
        ];
      };
    };

    prometheus = {
      enable = false;

      configText = ''
        global:
          scrape_interval: 1m
          scrape_timeout: 10s
          evaluation_interval: 1m

        scrape_configs:
        - job_name: node
          static_configs:
          - targets: ['localhost:9100']
      '';

      exporters.node.enable = false;
    };
  };
}
