{ config, lib, username, ... }:
{
  services.openssh.enable = true;

  users.users.${username}.openssh.authorizedKeys.keys = [
    config.flags.sshKeys.air
    config.flags.sshKeys.a3
  ];

  # macOS Sandbox blocks sshd from reading symlinks into /nix/store/.
  # Replace symlinks with copies so sshd can read them.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    for f in /etc/ssh/sshd_config.d/*.conf /etc/ssh/nix_authorized_keys.d/*; do
      if [ -L "$f" ]; then
        target=$(readlink -f "$f")
        if [ -f "$target" ]; then
          rm "$f"
          cp "$target" "$f"
        fi
      fi
    done
  '';
}
