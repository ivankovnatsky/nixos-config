{ pkgs, ... }:
{
  programs = {
    gpg = {
      enable = true;
    };
  };

  # Work around home-manager ordering cycle introduced by the ssh-auth-sock
  # module: set-SSH_AUTH_SOCK.service is `Before=gpg-agent-ssh.socket` but, via
  # default dependencies, also `After=basic.target`, while the socket ends up
  # `Before=sockets.target` -> basic.target. That closes a cycle and makes
  # `systemctl --user start basic.target` fail during activation. Dropping the
  # default deps from this trivial oneshot breaks the ordering cycle.
  systemd.user.services.set-SSH_AUTH_SOCK.Unit.DefaultDependencies = false;

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 60 * 60 * 12; # 12 hours
      maxCacheTtl = 60 * 60 * 12;
      pinentry.package = pkgs.pinentry-tty;
      extraConfig = ''
        allow-preset-passphrase
        no-allow-external-cache
      '';
    };
  };
}
