{ config, pkgs, ... }:

# mini runs check only, pointing at a3's serve over the LAN. No Anker creds here.
# ARMED: threshold 27, higher than a3's 25, so mini sheds first while a3's serve
# is still reachable; otherwise mini goes unreachable and won't shut down.
# Shutdown uses turnoff (osascript System Events) -- no sudo/root, works for the
# logged-in GUI user. NOTE: the launchd agent needs Automation (TCC) permission
# to control System Events; the first real shutdown may prompt/deny until granted.

let
  checkCmd = pkgs.writeShellScript "anker-monitor-check" ''
    exec ${pkgs.anker-monitor}/bin/anker-monitor check \
      --url http://${config.inventory.a3Ip}:8787/soc \
      --threshold 27 --debounce 1 --interval 900 \
      --shutdown --shutdown-cmd ${pkgs.turnoff}/bin/turnoff \
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
