{ config, pkgs, ... }:

let
  dataDir = "${config.flags.externalStoragePath}/.grafana";

  datasourcesConfig = pkgs.writeText "datasources.yaml" ''
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://${config.flags.machineIp}:3100
        isDefault: true
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://${config.flags.machineIp}:9090
  '';

  dashboardsConfig = pkgs.writeText "dashboards.yaml" ''
    apiVersion: 1
    providers:
      - name: default
        type: file
        options:
          path: ${pkgs.grafana}/share/grafana/public/dashboards
  '';

  # Admin password is initial only - changed via UI, stored in SQLite DB
  grafanaConfigTemplate = pkgs.writeText "grafana.ini.template" ''
    [paths]
    data = ${dataDir}
    logs = ${dataDir}/log
    plugins = ${dataDir}/plugins
    provisioning = ${dataDir}/provisioning

    [server]
    http_addr = ${config.flags.machineIp}
    http_port = 3000
    domain = grafana.@externalDomain@
    root_url = https://grafana.@externalDomain@
    enable_gzip = true

    [database]
    wal = true

    [security]
    admin_user = admin
    admin_password = admin
    disable_gravatar = true

    [analytics]
    reporting_enabled = false
    check_for_updates = false
    check_for_plugin_updates = false
    feedback_links_enabled = false

    [log]
    mode = console
  '';
in
{
  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  local.launchd.services.grafana = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.externalStoragePath;
    waitForSecrets = true;
    inherit dataDir;
    extraDirs = [
      "${dataDir}/log"
      "${dataDir}/plugins"
      "${dataDir}/provisioning/datasources"
      "${dataDir}/provisioning/dashboards"
    ];
    preStart = ''
      cp -f ${datasourcesConfig} ${dataDir}/provisioning/datasources/datasources.yaml
      cp -f ${dashboardsConfig} ${dataDir}/provisioning/dashboards/dashboards.yaml
      EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
      sed "s/@externalDomain@/$EXTERNAL_DOMAIN/g" ${grafanaConfigTemplate} > ${dataDir}/grafana.ini
    '';
    command = ''
      ${pkgs.grafana}/bin/grafana server \
        --homepath ${pkgs.grafana}/share/grafana \
        --config ${dataDir}/grafana.ini
    '';
  };
}
