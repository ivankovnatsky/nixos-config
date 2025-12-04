{ ... }:
{
  # Common sops secrets declarations for system-level (darwin/nixos)
  # Import this in machines that use sops for these secrets

  sops.secrets.external-domain = {
    key = "externalDomain";
    mode = "0444"; # Readable by all services
  };
}
