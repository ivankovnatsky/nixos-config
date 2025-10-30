{ config, ... }:
{
  imports = [
    ../shared/sops-nix.nix
    ./sops-secrets.nix
  ];

  # Use user SSH key for age decryption (home-manager needs user-owned secrets)
  sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
}
