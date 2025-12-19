{
  config,
  pkgs,
  username,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/.media";

  # Media directories - all subdirectories under Media/ except Stash
  mediaDir1 = "${config.flags.miniStoragePath}/Media/Audiobookshelf";
  mediaDir2 = "${config.flags.miniStoragePath}/Media/Downloads";
  mediaDir3 = "${config.flags.miniStoragePath}/Media/Movies";
  mediaDir4 = "${config.flags.miniStoragePath}/Media/Podcasts";
  mediaDir5 = "${config.flags.miniStoragePath}/Media/Podservice";
  mediaDir6 = "${config.flags.miniStoragePath}/Media/TV";
  mediaDir7 = "${config.flags.miniStoragePath}/Media/Textcast";
  mediaDir8 = "${config.flags.miniStoragePath}/Media/Youtube";

  # TODO:
  # - Hide sidebar in options permanently
  #   See: https://github.com/stashapp/stash/issues/2879

  # Template path (all substitutions happen at runtime to avoid secrets in /nix/store)
  stashConfigTemplate = ../../../../../templates/stash-config.yml;

  # Generate stash paths YAML for all media directories
  stashPathsYaml = ''
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir1}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir2}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir3}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir4}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir5}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir6}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir7}
    - excludeimage: false
      excludevideo: false
      path: ${mediaDir8}'';
in
{
  sops.secrets = {
    stash-media-username = {
      key = "media/username";
      owner = username;
    };
    stash-media-password = {
      key = "media/password";
      owner = username;
    };
  };

  local.launchd.services.stash-media = {
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

      # Read secrets from sops-decrypted files at runtime
      STASH_USERNAME=$(cat ${config.sops.secrets.stash-media-username.path})
      STASH_PASSWORD=$(cat ${config.sops.secrets.stash-media-password.path})

      # Generate stash paths section
      STASH_PATHS=$(cat <<'STASH_PATHS_EOF'
      ${stashPathsYaml}
      STASH_PATHS_EOF
      )

      # Substitute all values from template (keeps secrets out of /nix/store)
      sed -e "s|@dataDir@|${dataDir}|g" \
          -e "s|@host@|${config.flags.miniIp}|g" \
          -e "s|@port@|9998|g" \
          -e "s|@username@|$STASH_USERNAME|g" \
          -e "s|@password@|$STASH_PASSWORD|g" \
          -e "/@stashPaths@/r /dev/stdin" \
          -e "/@stashPaths@/d" \
          ${stashConfigTemplate} <<< "$STASH_PATHS" > ${dataDir}/config/config.yml

      chmod 644 ${dataDir}/config/config.yml
    '';
    command = ''
      script -q /dev/null ${pkgs.stash}/bin/stash --config ${dataDir}/config/config.yml
    '';
  };
}
