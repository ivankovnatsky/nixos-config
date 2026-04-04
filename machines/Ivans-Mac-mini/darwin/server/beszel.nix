{ config, pkgs, ... }:

{
  # Beszel Agent (monitoring mini itself) — runs as system daemon
  local.services.beszel-agent = {
    enable = true;
    package = pkgs.nixpkgs-darwin-master-beszel.beszel;
    port = 45876;
    listenAddress = config.flags.machineBindAddress;
    hubPublicKeyFile = config.sops.secrets.beszel-hub-public-key.path;
    waitForSecrets = true;
  };

  sops.secrets.beszel-hub-public-key = {
    key = "beszel/hubPublicKey";
  };
}
