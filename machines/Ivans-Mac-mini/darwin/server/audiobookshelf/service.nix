{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/.audiobookshelf";
  configDir = "${dataDir}/config";
  metadataDir = "${dataDir}/metadata";
in
{
  local.launchd.services.audiobookshelf = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      configDir
      metadataDir
    ];
    command = ''
      ${pkgs.audiobookshelf}/bin/audiobookshelf \
        --host ${config.flags.miniIp} \
        --port 8000 \
        --config ${configDir} \
        --metadata ${metadataDir}
    '';
    environment = {
      # Set NODE_ENV to production for better performance
      NODE_ENV = "production";
      # Disable telemetry
      SOURCE = "nixpkgs";
    };
  };
}
