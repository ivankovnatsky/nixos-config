{ ... }:

{
  sops.secrets.nextdns-api-key = {
    key = "nextDNS/common/apiKey";
    mode = "0400";
  };

  services.resolved.enable = true;

  # Stop dhcpcd from feeding DHCP-provided DNS into systemd-resolved.
  # Without this, every link gets DNS=192.168.50.1 (the router) plus
  # DefaultRoute=yes, which shadows the global [Resolve] drop-in below
  # and queries keep going to the router instead of our local resolver.
  networking.dhcpcd.extraConfig = "nohook resolv.conf";

  # Point resolved at the local resolver (dnsmasq from dns.nix).
  services.resolved.settings.Resolve.DNS = "127.0.0.1";

  # Avahi is the single mDNS responder on this host (see networking.nix).
  # Leaving resolved's full mDNS responder on too makes both daemons publish
  # a3.local, hear each other, declare a self-conflict, and loop forever
  # renaming a3 -> a4/a5/a7... ("Hostname conflict" spam in the journal).
  # "resolve" keeps resolved able to look up .local names but stops it from
  # registering/defending the hostname, ending the fight.
  services.resolved.settings.Resolve.MulticastDNS = "resolve";

  # The previous nextdns-resolved unit wrote /run/systemd/resolved.conf.d/
  # 10-nextdns.conf (and timestamped .bak files) directly. /run is tmpfs
  # so a reboot would clear them, but on a live nixos-rebuild switch they
  # linger and resolved reads them alongside the new config — leaving
  # stale DoT entries in the global DNS list.
  system.activationScripts.cleanup-nextdns-resolved-dropin = ''
    shopt -s nullglob
    files=(/run/systemd/resolved.conf.d/10-nextdns.conf{,.bak.*})
    if [ ''${#files[@]} -gt 0 ]; then
      rm -f -- "''${files[@]}"
    fi
  '';
}
