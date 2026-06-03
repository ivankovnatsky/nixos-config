{ config, lib, pkgs, ... }:

let
  dataDir = "/storage/data/media/podservice";
  audioDir = "${dataDir}/audio";
  metadataDir = "${dataDir}/metadata";
  thumbnailsDir = "${dataDir}/thumbnails";
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
    "f ${urlsFile}      0644 podservice podservice -"
  ];

  systemd.services.podservice = {
    description = "podservice YouTube-to-podcast server";
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = [ "/storage" ];
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
      StartLimitBurst = 10;
      StartLimitIntervalSec = 300;
    };
  };
}
