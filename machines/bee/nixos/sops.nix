{
  # Shared sops secrets for bee machine
  sops.secrets = {
    # Common secrets used across multiple services
    external-domain.key = "externalDomain";
    timezone.key = "timeZone";
  };
}
