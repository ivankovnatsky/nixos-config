{ config, lib, pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      extraOptions = {
        StrictHostKeyChecking = "accept-new";
      };
    };
  };

  home.activation.generateSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${config.home.homeDirectory}/.ssh/id_ed25519" ]; then
      $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.ssh"
      $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "${config.home.homeDirectory}/.ssh/id_ed25519" -N ""
      echo ""
      echo "Generated new SSH key. To use with sops-nix, add the age public key to .sops.yaml:"
      echo ""
      $DRY_RUN_CMD ${pkgs.ssh-to-age}/bin/ssh-to-age < "${config.home.homeDirectory}/.ssh/id_ed25519.pub"
      echo ""
    fi
  '';
}
