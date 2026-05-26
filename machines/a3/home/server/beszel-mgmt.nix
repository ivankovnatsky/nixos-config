{ config, osConfig, ... }:

{
  sops.secrets.beszel-email = {
    key = "beszel/email";
  };

  sops.secrets.beszel-password = {
    key = "beszel/password";
  };

  sops.secrets.discord-webhook-beszel = {
    key = "discord/webhooks/monitoringBeszel";
  };

  local.services.beszel-mgmt = {
    enable = true;
    externalDomainFile = config.sops.secrets.external-domain.path;
    systems = [
      {
        name = osConfig.networking.hostName;
        host = "127.0.0.1";
        port = "45876";
      }
    ];
  };
}
