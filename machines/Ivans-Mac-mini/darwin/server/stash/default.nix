{
  config,
  pkgs,
  ...
}:

let
  dataDir = "${config.flags.miniStoragePath}/.stash";
  stashDir = "${config.flags.miniStoragePath}/Media/Stash";

  # TODO:
  # - Hide sidebar in options permanently
  #   See: https://github.com/stashapp/stash/issues/2879

  # Template path (all substitutions happen at runtime to avoid secrets in /nix/store)
  stashConfigTemplate = ../../../../../templates/stash-config.yml;

  # Generate stash paths YAML for single directory
  stashPathsYaml = ''
    - excludeimage: false
      excludevideo: false
      path: ${stashDir}'';
in
{
  sops.secrets = {
    stash-username = {
      key = "stash/username";
      owner = "ivan";
    };
    stash-password = {
      key = "stash/password";
      owner = "ivan";
    };
  };

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

      # Read secrets from sops-decrypted files at runtime
      STASH_USERNAME=$(cat ${config.sops.secrets.stash-username.path})
      STASH_PASSWORD=$(cat ${config.sops.secrets.stash-password.path})

      # Generate stash paths section
      STASH_PATHS=$(cat <<'STASH_PATHS_EOF'
      ${stashPathsYaml}
      STASH_PATHS_EOF
      )

      # Substitute all values from template (keeps secrets out of /nix/store)
      sed -e "s|@dataDir@|${dataDir}|g" \
          -e "s|@host@|${config.flags.miniIp}|g" \
          -e "s|@port@|9999|g" \
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
