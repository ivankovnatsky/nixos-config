{ config, lib, pkgs, ... }:

let
  envFile = "/run/nextdns/env";
in
{
  # API key for nextdns-mgmt to look up the profile id by name. The id
  # itself never appears in nix store, sops, or any persistent file
  # outside /run (tmpfs).
  sops.secrets.nextdns-api-key = {
    key = "nextDnsApiKey";
    mode = "0400";
  };

  services.resolved.enable = true;

  # Stop dhcpcd from feeding DHCP-provided DNS into systemd-resolved.
  # Without this, every link gets DNS=192.168.50.1 (the router) plus
  # DefaultRoute=yes, which shadows the global [Resolve] drop-in below
  # and queries keep going to the router instead of nextdns.
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  # Point resolved at the local nextdns daemon.
  services.resolved.extraConfig = ''
    DNS=127.0.0.1
  '';

  # Render an EnvironmentFile with the looked-up profile id, before the
  # nextdns daemon starts. /run is tmpfs so the id never persists.
  systemd.services.nextdns-config = {
    description = "Render NextDNS daemon EnvironmentFile (profile id by name)";
    before = [ "nextdns.service" ];
    wantedBy = [ "nextdns.service" ];
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [
      "network-online.target"
      "sops-nix.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "nextdns";
      RuntimeDirectoryMode = "0750";
    };

    script = ''
      set -euo pipefail
      id=$(${pkgs.nextdns-mgmt}/bin/nextdns-mgmt lookup-id \
        --api-key "$(cat ${config.sops.secrets.nextdns-api-key.path})" \
        --resolver 1.1.1.1 \
        --name a3)

      # Defensive: refuse to write garbage into the env file. NextDNS
      # profile ids are short hex strings.
      if ! ${pkgs.gnugrep}/bin/grep -qE '^[0-9a-f]{6,}$' <<< "$id"; then
        echo "lookup-id returned unexpected value: $id" >&2
        exit 1
      fi

      umask 077
      echo "CONFIG_ID=$id" > ${envFile}
    '';
  };

  services.nextdns = {
    enable = true;
    # We override ExecStart below to interpolate ${CONFIG_ID} from the
    # EnvironmentFile, so leave arguments empty here.
    arguments = [ ];
  };

  systemd.services.nextdns = {
    after = [ "nextdns-config.service" ];
    requires = [ "nextdns-config.service" ];
    serviceConfig = {
      EnvironmentFile = envFile;
      ExecStart = lib.mkForce (
        "${pkgs.nextdns}/bin/nextdns run "
        + "-config \${CONFIG_ID} "
        + "-listen 127.0.0.1:53 "
        + "-report-client-info"
      );
    };
  };
}
