{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/.stash";
  mediaDir = "${config.flags.miniStoragePath}/Stash";
  youtubeDir = "${config.flags.miniStoragePath}/Youtube";
  mediaDir2 = "${config.flags.miniStoragePath}/Media";

  # TODO:
  # - Hide sidebar in options permanently
  #   See: https://github.com/stashapp/stash/issues/2879

  # Stash configuration template (will be processed with variable substitution)
  stashConfig = pkgs.replaceVars ../../../../../templates/stash-config.yml {
    inherit
      dataDir
      mediaDir
      youtubeDir
      mediaDir2
      ;
    host = config.flags.miniIp;
    inherit (config.secrets.stash) username password;
  };
in
{
  local.launchd.services.stash = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [
      "${dataDir}/logs"
      "${dataDir}/config"
      "${dataDir}/generated"
      "${dataDir}/cache"
      "${dataDir}/blobs"
      "${dataDir}/metadata"
    ];
    preStart = ''
      export PATH="${pkgs.ffmpeg}/bin:$PATH"

      if [ -f "${dataDir}/config/config.yml" ]; then
        cp "${dataDir}/config/config.yml" "${dataDir}/config/config.yml.backup.$(date +%Y%m%d-%H%M%S)"
      fi
      cp ${stashConfig} ${dataDir}/config/config.yml
      chmod 644 ${dataDir}/config/config.yml
    '';
    command = ''
      script -q /dev/null ${pkgs.stash}/bin/stash --config ${dataDir}/config/config.yml
    '';
  };
}
