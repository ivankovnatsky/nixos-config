{ config, pkgs, ... }:

{
  # TODO:
  # 1. Make sure we have aggresive retention of storage till we have a bigger disk
  # Enable Grafana service
  services.grafana = {
    enable = true;
    settings = {
      server = {
        # Listen on all interfaces
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "grafana.beelink.home.lan";
        root_url = "http://grafana.beelink.home.lan";
      };
      # Default admin user
      security = {
        admin_user = "admin";
        # Default password - change this after first login
        admin_password = "admin";
      };
    };

    # Provision some default dashboards and datasources
    provision = {
      enable = true;
      datasources = {
        settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://localhost:3100";
              isDefault = true;
            }
          ];
        };
      };
      dashboards = {
        settings = {
          apiVersion = 1;
          providers = [
            {
              name = "default";
              type = "file";
              options.path = "${pkgs.grafana}/share/grafana/public/dashboards";
            }
          ];
        };
      };
    };
  };

  # Enable Loki service with updated configuration
  services.loki = {
    enable = true;
    extraFlags = [ "-config.expand-env=true" ];
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_port = 3100;
        grpc_listen_port = 9096; # Changed from default 9095
      };
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 1048576;
        chunk_retain_period = "30s";
      };
      schema_config = {
        configs = [
          {
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        # Disable structured metadata to fix validation error
        allow_structured_metadata = false;
        # Increase rate limits to handle higher log volumes from promtail clients
        ingestion_rate_mb = 16; # 16MB per second instead of default 4MB
        ingestion_burst_size_mb = 32; # 32MB burst size
        per_stream_rate_limit = "10MB"; # Per stream rate limit
        max_entries_limit_per_query = 10000; # Max entries per query
      };
      chunk_store_config = {
        # Empty but needed
      };
      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        compaction_interval = "10m";
        # Disable retention to fix validation error
        retention_enabled = false;
      };
      ruler = {
        storage = {
          type = "local";
          local = {
            directory = "/var/lib/loki/rules";
          };
        };
        rule_path = "/var/lib/loki/rules";
        alertmanager_url = "http://localhost:9093";
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
        enable_api = true;
      };
    };
  };

  # Configure Promtail user and group
  users.groups.promtail = { };
  users.users.promtail = {
    isSystemUser = true;
    group = "promtail";
    extraGroups = [
      "systemd-journal" # For journal access
      "adm" # For /var/log access
      "caddy" # For caddy logs
      "nginx" # For nginx logs
      "dnsmasq" # For dnsmasq logs
    ];
  };

  # Configure Loki user and group
  users.groups.loki = { };
  users.users.loki = {
    isSystemUser = true;
    group = "loki";
  };

  # Ensure log directories have correct permissions
  systemd.tmpfiles.rules = [
    "d /var/log/services 0755 root root"
    "d /var/lib/loki 0750 loki loki -"
    "d /var/lib/loki/chunks 0750 loki loki -"
    "d /var/lib/loki/boltdb-shipper-active 0750 loki loki -"
    "d /var/lib/loki/boltdb-shipper-cache 0750 loki loki -"
    "d /var/lib/loki/compactor 0750 loki loki -"
    "d /var/lib/loki/rules 0750 loki loki -"
    "d /var/lib/promtail 0750 promtail promtail -"
  ];

  # Enable Promtail service for log collection
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 9097; # Changed from default 9095
      };
      positions = {
        filename = "/var/lib/promtail/positions.yaml";
      };
      clients = [
        {
          url = "http://localhost:3100/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "beelink";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
            {
              source_labels = [ "__journal__hostname" ];
              target_label = "hostname";
            }
          ];
        }
        {
          job_name = "system";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "system";
                host = "beelink";
                __path__ = "/var/log/*.log";
              };
            }
          ];
        }
        {
          job_name = "services";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "services";
                host = "beelink";
                __path__ = "/var/log/services/*.log";
              };
            }
          ];
        }
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "nginx";
                host = "beelink";
                __path__ = "/var/log/nginx/*.log";
              };
            }
          ];
        }
        {
          job_name = "caddy";
          static_configs = [
            {
              targets = [ "localhost" ];
              labels = {
                job = "caddy";
                host = "beelink";
                __path__ = "/var/log/caddy/*.log";
              };
            }
          ];
        }
      ];
    };
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    3100 # Loki
    9080 # Promtail
    9096 # Loki GRPC
    9097 # Promtail GRPC
  ];
}
