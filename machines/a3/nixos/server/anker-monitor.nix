{ config, pkgs, ... }:

let
  # ARMED: threshold 25%, debounce 1, every 15m. Runs as root so `systemctl
  # poweroff` needs no polkit/sudo grant (a user service is denied -- polkit
  # requires an active seat session, which a lingering user manager lacks).
  checkCmd = pkgs.writeShellScript "anker-monitor-check-a3" ''
    exec ${pkgs.anker-monitor}/bin/anker-monitor check \
      --url http://127.0.0.1:8787/soc \
      --threshold 25 --debounce 1 --interval 900 \
      --shutdown --shutdown-cmd '${config.systemd.package}/bin/systemctl poweroff' \
      --webhook-file ${config.sops.secrets.anker-discord-webhook.path}
  '';
in
{
  # anker-monitor serve (home-manager user service) binds 0.0.0.0:8787 so the
  # Mac mini can poll SOC over the LAN. The home module can't touch the system
  # firewall, so open the port here.
  networking.firewall.allowedTCPPorts = [ 8787 ];

  # Root-owned so the root check service can read it (default 0400 root:root).
  sops.secrets.anker-discord-webhook = { key = "discord/webhooks/notifications"; };

  # Actor: poll the local serve endpoint and power a3 off on sustained low SOC.
  # Root system service (not a user service) so poweroff needs no auth. No Anker
  # creds here -- it only talks to localhost:8787.
  systemd.services.anker-monitor-check = {
    description = "Anker C1000 low-battery shutdown check (a3)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${checkCmd}";
      Restart = "always";
      RestartSec = 30;
    };
  };
}
