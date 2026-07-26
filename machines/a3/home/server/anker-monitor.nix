{ config, pkgs, ... }:

# a3 runs the single serve (Anker cloud reader) + its own check. mini also runs a
# check pointing at a3 over the LAN (see machines/Ivans-Mac-mini/home/server).
# Dry-run for now: check has no --shutdown, so it only logs "would run".

{
  sops.secrets.anker-email = { key = "anker/email"; };
  sops.secrets.anker-password = { key = "anker/password"; };
  sops.secrets.anker-country = { key = "anker/country"; };

  # Reuse the shared notifications Discord channel for critical alerts.
  sops.secrets.anker-discord-webhook = { key = "discord/webhooks/notifications"; };

  # One combined secrets file for anker-monitor --secrets-file.
  sops.templates."anker-secrets".content = ''
    email: ${config.sops.placeholder.anker-email}
    password: ${config.sops.placeholder.anker-password}
    country: ${config.sops.placeholder.anker-country}
  '';

  # Reporter: reads C1000 SOC over Anker cloud MQTT, exposes GET /soc on the LAN.
  systemd.user.services.anker-monitor-serve = {
    Unit = {
      Description = "Anker C1000 SOC reporter";
      After = [ "network-online.target" "sops-nix.service" ];
      Wants = [ "network-online.target" "sops-nix.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = ''
        ${pkgs.anker-monitor}/bin/anker-monitor serve \
          --host 0.0.0.0 --port 8787 \
          --secrets-file ${config.sops.templates."anker-secrets".path}
      '';
      Restart = "always";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Actor (a3): poll localhost /soc, shut a3 down on sustained low battery.
  # DRY-RUN: no --shutdown. threshold 25, debounce 1, every 15m.
  systemd.user.services.anker-monitor-check = {
    Unit = {
      Description = "Anker C1000 low-battery shutdown check (dry-run)";
      After = [ "anker-monitor-serve.service" ];
      Wants = [ "anker-monitor-serve.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = ''
        ${pkgs.anker-monitor}/bin/anker-monitor check \
          --url http://127.0.0.1:8787/soc \
          --threshold 25 --debounce 1 --interval 900 \
          --webhook-file ${config.sops.secrets.anker-discord-webhook.path}
      '';
      Restart = "always";
      RestartSec = 30;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
