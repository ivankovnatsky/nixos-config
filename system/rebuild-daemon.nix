{
  config,
  username ? null,
  ...
}:
{
  local.services.rebuildDaemon = {
    enable = true;
    # Always use home directory - TCC blocks daemons from /Volumes on macOS
    configPath = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
