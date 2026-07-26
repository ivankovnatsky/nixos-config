{ config, pkgs, ... }:

# mini runs check only, pointing at a3's serve over the LAN. No Anker creds here.
# DRY-RUN for now: no --shutdown, only logs "would run".
# NOTE at arming: a3 hosts serve, so a3 must power off LAST. Give mini a slightly
# higher threshold than a3 (e.g. mini 27 / a3 25) so mini shuts first while a3's
# serve is still reachable; otherwise mini goes unreachable and won't shut down.

let
  checkCmd = pkgs.writeShellScript "anker-monitor-check" ''
    exec ${pkgs.anker-monitor}/bin/anker-monitor check \
      --url http://${config.inventory.a3Ip}:8787/soc \
      --threshold 27 --debounce 1 --interval 900 \
      --webhook-file ${config.sops.secrets.anker-discord-webhook.path}
  '';
in
{
  # Reuse the shared notifications Discord channel for critical alerts.
  sops.secrets.anker-discord-webhook = { key = "discord/webhooks/notifications"; };

  local.launchd.services.anker-monitor-check = {
    enable = true;
    runAtLoad = true;
    keepAlive = true;
    waitForSecrets = true;
    command = "${checkCmd}";
  };
}
