{ config, ... }:
{
  # Shared sops secrets for bee machine
  sops.secrets = {
    # Common secrets used across multiple services
    external-domain.key = "externalDomain";
    timezone.key = "timeZone";

    # Transmission credentials
    transmission-username.key = "transmission/username";
    transmission-password.key = "transmission/password";
  };

  # Sops template for transmission auth
  sops.templates."transmission-auth.env" = {
    content = ''
      export TR_AUTH="${config.sops.placeholder.transmission-username}:${config.sops.placeholder.transmission-password}"
    '';
    mode = "0444";
  };
}
