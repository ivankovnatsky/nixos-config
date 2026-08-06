{ config, pkgs, ... }:

{
  # Agent stores the hub's SSH public key it expects inbound connections from
  # (hub runs on a3). beszel-agent reads it from the file pointed to by
  # KEY_FILE, so pass the sops secret path directly.
  sops.secrets.beszel-hub-public-key = {
    key = "beszel/hubPublicKey";
  };

  local.launchd.services.beszel-agent = {
    enable = true;
    waitForSecrets = true;
    environment = {
      LISTEN = "0.0.0.0:45876";
      KEY_FILE = config.sops.secrets.beszel-hub-public-key.path;
    };
    command = "${pkgs.beszel}/bin/beszel-agent";
  };
}
