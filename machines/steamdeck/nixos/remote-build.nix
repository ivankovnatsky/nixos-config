{
  config,
  pkgs,
  username,
  ...
}:

let
  homeDir = config.users.users.${username}.home;
  keyPath = "${homeDir}/.ssh/nixbuilder";
in
{
  # Generate SSH key for ivan to connect to remote builder (idempotent)
  systemd.services.generate-nixbuilder-ssh-key = {
    description = "Generate SSH key for remote builds";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = username;
      Group = "users";
    };
    script = ''
      if [ ! -f ${keyPath} ]; then
        mkdir -p ${homeDir}/.ssh
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ${keyPath} -N "" -C "${username}@steamdeck"
        chmod 600 ${keyPath}
        chmod 644 ${keyPath}.pub
      fi
    '';
  };

  # To manually generate the key:
  # ssh-keygen -t ed25519 -f ~/.ssh/nixbuilder -N "" -C "ivan@steamdeck"
  # Then copy the public key to modules/flags/default.nix:
  # cat ~/.ssh/nixbuilder.pub

  # Configure SSH to connect to a3's nixbuilder user
  programs.ssh.extraConfig = ''
    Host a3
      HostName ${config.flags.a3Ip}
      IdentitiesOnly yes
      IdentityFile ${keyPath}
      User nixbuilder
      StrictHostKeyChecking accept-new
  '';
}
