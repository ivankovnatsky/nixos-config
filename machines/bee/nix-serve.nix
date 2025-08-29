{ config, pkgs, lib, ... }:

{
  # Enable nix-serve for binary cache
  services.nix-serve = {
    enable = true;
    # Bind to bee's IP address
    bindAddress = config.flags.beeIp;
    port = 5000;
    # Generate a signing key for the cache
    secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
  };

  # Create the signing key if it doesn't exist
  systemd.services.nix-serve-keygen = {
    description = "Generate Nix cache signing key";
    serviceConfig = {
      Type = "oneshot";
      User = "nix-serve";
      Group = "nix-serve";
    };
    script = ''
      if [[ ! -f /var/lib/nix-serve/cache-priv-key.pem ]]; then
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key ${config.networking.hostName} /var/lib/nix-serve/cache-priv-key.pem /var/lib/nix-serve/cache-pub-key.pem
      fi
    '';
    before = [ "nix-serve.service" ];
    requiredBy = [ "nix-serve.service" ];
  };

  # Create the nix-serve user properly
  users.users.nix-serve = {
    isSystemUser = true;
    group = "nix-serve";
    extraGroups = [ "nixbld" ];
  };
  
  users.groups.nix-serve = {};

  # Create the nix-serve state directory
  systemd.tmpfiles.rules = [
    "d /var/lib/nix-serve 0755 nix-serve nix-serve -"
  ];
}