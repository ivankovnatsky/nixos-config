{ config, lib, ... }:
{
  imports = [
    ../../../home/sops-secrets.nix
    ../../../shared/sops-nix.nix
  ];

  # Use user SSH key for age decryption (home-manager needs user-owned secrets)
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  # WORKAROUND: Upstream sops-nix sets KeepAlive=false for the launchd agent,
  # so if sops-install-secrets fails at boot (SSH key not readable yet), it
  # never retries and secrets stay broken until next darwin-rebuild switch.
  # https://github.com/Mic92/sops-nix/issues/801
  launchd.agents.sops-nix.config.KeepAlive.SuccessfulExit = lib.mkForce false;
}
