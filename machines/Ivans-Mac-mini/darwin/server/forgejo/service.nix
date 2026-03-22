{
  config,
  pkgs,
  username,
  ...
}:

let
  forgejoDataPath = "${config.flags.externalStoragePath}/.forgejo";
  httpPort = "3300";
  sshPort = "2222";
  runtimeAppIni = "${forgejoDataPath}/app.ini";
in
{
  local.launchd.services.forgejo = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.externalStoragePath;
    waitForSecrets = true;
    dataDir = forgejoDataPath;
    environment = {
      HOME = config.users.users.${username}.home;
      FORGEJO_WORK_DIR = forgejoDataPath;
    };
    command =
      let
        startScript = pkgs.writeShellScript "forgejo-start" ''
          set -e

          EXTERNAL_DOMAIN="$(cat ${config.sops.secrets.external-domain.path})"

          mkdir -p "${forgejoDataPath}/data" \
                   "${forgejoDataPath}/repos" \
                   "${forgejoDataPath}/data/lfs" \
                   "${forgejoDataPath}/data/sessions" \
                   "${forgejoDataPath}/data/avatars" \
                   "${forgejoDataPath}/data/repo-avatars" \
                   "${forgejoDataPath}/log"

          cat > ${runtimeAppIni} << EOF
          APP_NAME = Forgejo
          RUN_MODE = prod

          [server]
          HTTP_ADDR = ${config.flags.machineBindAddress}
          HTTP_PORT = ${httpPort}
          ROOT_URL = https://forgejo.$EXTERNAL_DOMAIN/
          SSH_DOMAIN = forgejo.$EXTERNAL_DOMAIN
          START_SSH_SERVER = true
          SSH_PORT = ${sshPort}
          SSH_LISTEN_PORT = ${sshPort}
          LFS_START_SERVER = true
          LFS_JWT_SECRET_URI = file:${forgejoDataPath}/jwt_secret

          [database]
          DB_TYPE = sqlite3
          PATH = ${forgejoDataPath}/data/forgejo.db

          [repository]
          ROOT = ${forgejoDataPath}/repos

          [lfs]
          PATH = ${forgejoDataPath}/data/lfs

          [log]
          ROOT_PATH = ${forgejoDataPath}/log

          [security]
          INSTALL_LOCK = true
          SECRET_KEY_URI = file:${forgejoDataPath}/secret_key
          INTERNAL_TOKEN_URI = file:${forgejoDataPath}/internal_token

          [service]
          DISABLE_REGISTRATION = true

          [oauth2]
          JWT_SECRET_URI = file:${forgejoDataPath}/oauth2_jwt_secret

          [session]
          PROVIDER = file
          PROVIDER_CONFIG = ${forgejoDataPath}/data/sessions

          [picture]
          AVATAR_UPLOAD_PATH = ${forgejoDataPath}/data/avatars
          REPOSITORY_AVATAR_UPLOAD_PATH = ${forgejoDataPath}/data/repo-avatars
          EOF

          chmod 600 ${runtimeAppIni}

          # Generate secrets on first run (Forgejo requires these with INSTALL_LOCK=true)
          generate_secret() {
            local file="$1" type="$2"
            if [ ! -f "${forgejoDataPath}/$file" ]; then
              ${pkgs.forgejo}/bin/forgejo generate secret "$type" > "${forgejoDataPath}/$file"
              chmod 600 "${forgejoDataPath}/$file"
            fi
          }
          generate_secret secret_key SECRET_KEY
          generate_secret internal_token INTERNAL_TOKEN
          generate_secret jwt_secret JWT_SECRET
          generate_secret oauth2_jwt_secret JWT_SECRET

          exec ${pkgs.forgejo}/bin/forgejo web --config ${runtimeAppIni}
        '';
      in
      "${startScript}";
  };
}
