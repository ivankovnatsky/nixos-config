{
  config,
  lib,
  pkgs,
  ...
}:
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
      echo "Generated new SSH key."
    fi
    echo "age public key: $($DRY_RUN_CMD ${pkgs.ssh-to-age}/bin/ssh-to-age < "${config.home.homeDirectory}/.ssh/id_ed25519.pub")"
  '';
}
