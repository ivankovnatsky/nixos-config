{ config, ... }:

{
  # System-level sops secret holding the NextDNS profile ID for "a3".
  # Add the encrypted value under key `nextDnsProfileA3` in secrets/default.yaml.
  # Fetch the current ID with:
  #   nextdns-mgmt update --api-key "$(sops -d --extract '["nextDnsApiKey"]' \
  #     secrets/default.yaml)" --name a3 --profile-file configs/nextdns-profile.json --dry-run
  # The "Resolved profile 'a3' → <id>" line on stderr is what to encrypt.
  sops.secrets.nextdns-profile-a3 = {
    key = "nextDnsProfileA3";
    mode = "0400";
  };

  # Render a systemd-resolved drop-in with the profile ID interpolated at
  # activation time. The rendered file lives under /run (tmpfs), so the ID
  # never lands in the nix store and only root can read it.
  sops.templates."resolved-nextdns.conf" = {
    path = "/run/systemd/resolved.conf.d/10-nextdns.conf";
    mode = "0444";
    content = ''
      [Resolve]
      DNS=45.90.28.0#${config.sops.placeholder.nextdns-profile-a3}.dns.nextdns.io
      DNS=2a07:a8c0::#${config.sops.placeholder.nextdns-profile-a3}.dns.nextdns.io
      DNS=45.90.30.0#${config.sops.placeholder.nextdns-profile-a3}.dns.nextdns.io
      DNS=2a07:a8c1::#${config.sops.placeholder.nextdns-profile-a3}.dns.nextdns.io
      DNSOverTLS=yes
    '';
  };

  services.resolved.enable = true;
}
