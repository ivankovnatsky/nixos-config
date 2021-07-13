{ pkgs, ... }:

{
  services = {
    grafana = {
      enable = true;

      provision = {
        enable = true;

        datasources = [{
          type = "prometheus";
          name = "Prometheus";
          isDefault = true;
          url = "http://localhost:9090";
        }];
      };
    };

    prometheus = {
      enable = true;

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

      exporters.node.enable = true;
    };
  };
}
