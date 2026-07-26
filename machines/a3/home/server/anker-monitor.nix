{ config, pkgs, ... }:

# a3 runs the serve reporter (Anker cloud reader) as a user service. The actor
# (low-battery check) runs as a ROOT system service instead, because a user
# service can't `systemctl poweroff` (polkit needs an active seat session, which
# a lingering user manager lacks) -- see machines/a3/nixos/server/anker-monitor.nix.
# mini also runs a check pointing at a3 over the LAN (see
# machines/Ivans-Mac-mini/home/server).

{
  sops.secrets.anker-email = { key = "anker/email"; };
  sops.secrets.anker-password = { key = "anker/password"; };
  sops.secrets.anker-country = { key = "anker/country"; };

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
}
