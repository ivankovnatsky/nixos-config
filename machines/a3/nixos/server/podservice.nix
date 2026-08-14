{
  config,
  lib,
  pkgs,
  ...
}:

let
  dataDir = "/storage/data/media/podservice";
  audioDir = "${dataDir}/audio";
  metadataDir = "${dataDir}/metadata";
  thumbnailsDir = "${dataDir}/thumbnails";
  dbDir = "${dataDir}/db";
  urlsFile = "${dataDir}/urls.txt";

  configFile = pkgs.writeText "podservice-config.yaml" (
    builtins.toJSON {
      server = {
        port = 8083;
        host = "0.0.0.0";
        base_url = "https://podservice.@EXTERNAL_DOMAIN@";
      };
      podcast = {
        title = "A3: My YouTube Podcast";
        description = "YouTube videos converted to podcast episodes";
        author = "Ivan Kovnatsky";
        language = "en-us";
        category = "Technology";
      };
      storage = {
        data_dir = dataDir;
        audio_dir = audioDir;
        metadata_dir = metadataDir;
        thumbnails_dir = thumbnailsDir;
      };
      watch = {
        enabled = true;
        file = urlsFile;
      };
      rabbitmq = {
        host = "127.0.0.1";
        port = 5672;
        username = "guest";
        virtual_host = "/";
        exchange = "podservice.commands";
        queue = "podservice.downloads";
        routing_key = "download.requested";
        retry_delays = [
          30
          300
          1800
        ];
        reconnect_delay = 5;
      };
      kafka = {
        enabled = true;
        bootstrap_servers = [ "127.0.0.1:9092" ];
        topic = "podservice.lifecycle";
        consumer_group = "podservice-dashboard";
        client_id = "podservice-a3";
        topic_partitions = 1;
        topic_replication_factor = 1;
        reconnect_delay = 5;
      };
      log_level = "INFO";
    }
  );

  runtimeConfigFile = pkgs.writeShellScript "podservice-config-gen" ''
    set -e
    EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
    ${pkgs.gnused}/bin/sed \
      -e "s|@EXTERNAL_DOMAIN@|$EXTERNAL_DOMAIN|g" \
      ${configFile}
  '';
in
{
  services.rabbitmq = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 5672;
    managementPlugin.enable = true;
  };

  services.apache-kafka = {
    enable = true;
    clusterId = "J9MCrGnTROKNUU9vsEoQjw";
    formatLogDirs = true;
    formatLogDirsIgnoreFormatted = true;
    jvmOptions = [
      "-Xms256M"
      "-Xmx512M"
    ];
    settings = {
      "node.id" = 1;
      "process.roles" = [
        "broker"
        "controller"
      ];
      "controller.quorum.voters" = [ "1@127.0.0.1:9093" ];
      "controller.listener.names" = [ "CONTROLLER" ];
      "listener.security.protocol.map" = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT";
      "inter.broker.listener.name" = "PLAINTEXT";
      "listeners" = [
        "PLAINTEXT://127.0.0.1:9092"
        "CONTROLLER://127.0.0.1:9093"
      ];
      "advertised.listeners" = [
        "PLAINTEXT://127.0.0.1:9092"
        "CONTROLLER://127.0.0.1:9093"
      ];
      "log.dirs" = [ "/var/lib/apache-kafka" ];
      "num.partitions" = 1;
      "default.replication.factor" = 1;
      "offsets.topic.replication.factor" = 1;
      "transaction.state.log.replication.factor" = 1;
      "transaction.state.log.min.isr" = 1;
      "group.initial.rebalance.delay.ms" = 0;
      "auto.create.topics.enable" = false;
      "log.retention.hours" = 720;
    };
  };

  systemd.services.apache-kafka.serviceConfig.StateDirectory = "apache-kafka";
  systemd.services.apache-kafka.serviceConfig.Restart = "on-failure";
  systemd.services.apache-kafka.serviceConfig.RestartSec = 10;

  networking.firewall.allowedTCPPorts = [ 8083 ];

  users.users.podservice = {
    isSystemUser = true;
    group = "podservice";
    description = "podservice YouTube-to-podcast service user";
  };

  users.groups.podservice = { };

  systemd.tmpfiles.rules = [
    # podservice YouTube-to-podcast data; owned by the dedicated service user.
    "d ${dataDir}       0755 podservice podservice -"
    "d ${audioDir}      0755 podservice podservice -"
    "d ${metadataDir}   0755 podservice podservice -"
    "d ${thumbnailsDir} 0755 podservice podservice -"
    "d ${dbDir}         0755 podservice podservice -"
    "f ${urlsFile}      0644 podservice podservice -"
  ];

  systemd.services.podservice = {
    description = "podservice YouTube-to-podcast server";
    after = [
      "network-online.target"
      "rabbitmq.service"
      "apache-kafka.service"
      "sops-nix.service"
    ];
    requires = [
      "rabbitmq.service"
    ];
    wants = [
      "network-online.target"
      "apache-kafka.service"
    ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      RequiresMountsFor = [ "/storage" ];
      StartLimitBurst = 10;
      StartLimitIntervalSec = 300;
    };
    environment = {
      PATH = lib.mkForce "${pkgs.coreutils}/bin:${pkgs.ffmpeg}/bin";
    };
    serviceConfig = {
      User = "podservice";
      Group = "podservice";
      ExecStartPre = pkgs.writeShellScript "podservice-prestart" ''
        ${runtimeConfigFile} > ${dataDir}/config.yaml
      '';
      ExecStart = "${pkgs.podservice}/bin/podservice serve --config=${dataDir}/config.yaml";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
