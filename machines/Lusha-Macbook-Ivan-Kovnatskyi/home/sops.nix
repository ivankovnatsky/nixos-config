{ config, ... }:
{
  imports = [
    ../../../home/sops-secrets.nix
    ../../../secrets/sops-nix.nix
  ];

  # Use user SSH key for age decryption (home-manager needs user-owned secrets)
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
}
