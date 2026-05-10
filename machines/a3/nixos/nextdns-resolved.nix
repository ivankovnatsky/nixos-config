{ config, pkgs, ... }:

let
  resolvedDir = "/run/systemd/resolved.conf.d";
  resolvedConf = "${resolvedDir}/10-nextdns.conf";
in
{
  # System-level NextDNS API key. Needed at root because the unit below runs
  # at boot, before any user session exists.
  sops.secrets.nextdns-api-key = {
    key = "nextDnsApiKey";
    mode = "0400";
  };

  services.resolved.enable = true;

  # Fetch the NextDNS profile id by name at boot, render the resolved drop-in
  # to /run, and reload systemd-resolved. The profile id never appears in the
  # nix store, in sops, or in any persistent file outside /run (tmpfs).
  systemd.services.nextdns-resolved = {
    description = "Render systemd-resolved drop-in for NextDNS by profile name";
    wantedBy = [ "multi-user.target" ];
    before = [ "systemd-resolved.service" ];
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
    };

    script = ''
      set -euo pipefail
      mkdir -p ${resolvedDir}

      tmp=${resolvedConf}.tmp
      # Pin DNS to a public resolver: this unit runs Before=
      # systemd-resolved.service, so the stub resolver isn't up yet and
      # getaddrinfo("api.nextdns.io") would fail at boot.
      ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt resolved-config \
        --api-key "$(cat ${config.sops.secrets.nextdns-api-key.path})" \
        --resolver 1.1.1.1 \
        --name a3 > "$tmp"

      # Sanity-check the rendered drop-in before promoting it. If the API
      # returned garbage we keep the previous file (or no file at all) so
      # systemd-resolved doesn't fall back to a broken state.
      if ! ${pkgs.gnugrep}/bin/grep -q '^\[Resolve\]' "$tmp" \
        || ! ${pkgs.gnugrep}/bin/grep -q '^DNS=' "$tmp" \
        || ! ${pkgs.gnugrep}/bin/grep -q '^DNSOverTLS=yes' "$tmp"; then
        echo "rendered drop-in failed validation, keeping previous" >&2
        rm -f "$tmp"
        exit 1
      fi

      # Back up the previous file with a timestamp before overwriting.
      if [ -e ${resolvedConf} ]; then
        ${pkgs.coreutils}/bin/cp -p ${resolvedConf} \
          ${resolvedConf}.bak."$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      fi

      mv -f "$tmp" ${resolvedConf}

      # No reload here: Before=systemd-resolved.service guarantees resolved
      # reads the drop-in on its initial start. Queuing a reload from here
      # creates an ordering cycle (resolved is ordered after us, the reload
      # job would be ordered after resolved). For runtime config changes,
      # run `sudo systemctl reload systemd-resolved` manually.
    '';
  };
}
