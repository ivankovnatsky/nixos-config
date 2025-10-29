{ config, ... }:
{
  imports = [
    ../../../shared/sops-nix.nix
  ];

  # Use SSH host key for age decryption
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.gh-mcp-token = {
    key = "ghMcpToken";
  };
}
