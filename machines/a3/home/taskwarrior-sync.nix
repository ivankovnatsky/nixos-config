{
  config,
  lib,
  osConfig,
  pkgs,
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
    domain="$(cat ${config.sops.secrets.external-domain.path})"
    (umask 077; cat > ${secretsFile} <<TASKRC
sync.encryption_secret=$encryption_secret
sync.server.client_id=$client_id
sync.server.url=https://taskchampion.$domain
TASKRC
    )
  '';

  programs.taskwarrior = {
    extraConfig = ''
      include ${secretsFile}
    '';
  };

  systemd.user.services.taskwarrior-sync = {
    Unit = {
      Description = "Taskwarrior sync";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.taskwarrior3}/bin/task rc.verbose=sync sync";
    };
  };

  systemd.user.timers.taskwarrior-sync = {
    Unit = {
      Description = "Taskwarrior sync timer";
    };
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "15min";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
