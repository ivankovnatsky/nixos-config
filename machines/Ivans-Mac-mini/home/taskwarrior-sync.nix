{
  config,
  lib,
  osConfig,
  ...
}:
let
  hostname = osConfig.networking.hostName;
  secretsFile = "${config.xdg.configHome}/task/taskrc.secrets";
in
{
  sops.secrets.taskchampion-encryption-secret = {
    key = "taskchampion/encryptionSecret";
  };

  sops.secrets.taskchampion-client-id = {
    key = "taskchampion/clientId/${hostname}";
  };

  home.activation.taskwarriorSecrets = lib.hm.dag.entryAfter [ "writeBoundary" "sopsNix" ] ''
    encryption_secret="$(cat ${config.sops.secrets.taskchampion-encryption-secret.path})"
    client_id="$(cat ${config.sops.secrets.taskchampion-client-id.path})"
    (umask 077; cat > ${secretsFile} <<TASKRC
sync.encryption_secret=$encryption_secret
sync.server.client_id=$client_id
TASKRC
    )
  '';

  programs.taskwarrior = {
    config = {
      "sync.server.url" = "http://${config.flags.miniIp}:10222";
    };
    extraConfig = ''
      include ${secretsFile}
    '';
  };
}
