{ config, pkgs, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.loki";

  lokiConfig = pkgs.writeText "loki-config.yaml" ''
    auth_enabled: false

    server:
      http_listen_address: ${config.flags.miniIp}
      http_listen_port: 3100
      grpc_listen_port: 9096
      grpc_server_max_concurrent_streams: 1000

    common:
      instance_addr: 127.0.0.1
      path_prefix: ${dataDir}
      storage:
        filesystem:
          chunks_directory: ${dataDir}/chunks
          rules_directory: ${dataDir}/rules
      replication_factor: 1
      ring:
        kvstore:
          store: inmemory

    query_range:
      results_cache:
        cache:
          embedded_cache:
            enabled: true
            max_size_mb: 100

    schema_config:
      configs:
        - from: 2020-10-24
          store: tsdb
          object_store: filesystem
          schema: v13
          index:
            prefix: index_
            period: 24h

    limits_config:
      reject_old_samples: true
      reject_old_samples_max_age: 168h
      allow_structured_metadata: false
      ingestion_rate_mb: 16
      ingestion_burst_size_mb: 32
      per_stream_rate_limit: 10MB
      max_entries_limit_per_query: 10000
      metric_aggregation_enabled: true

    pattern_ingester:
      enabled: true
      metric_aggregation:
        loki_address: localhost:3100

    frontend:
      encoding: protobuf

    compactor:
      working_directory: ${dataDir}/compactor
      compaction_interval: 10m
      retention_enabled: false

    ruler:
      alertmanager_url: http://localhost:9093
      storage:
        type: local
        local:
          directory: ${dataDir}/rules

    analytics:
      reporting_enabled: false
  '';
in
{
  local.launchd.services.loki = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      "${dataDir}/chunks"
      "${dataDir}/rules"
      "${dataDir}/compactor"
    ];
    command = ''
      ${pkgs.grafana-loki}/bin/loki \
        -config.file=${lokiConfig} \
        -config.expand-env=true
    '';
  };
}
