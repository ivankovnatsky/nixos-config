{
  config,
  username ? null,
  ...
}:
{
  local.services.rebuildTerminal = {
    enable = true;
    configPath = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
  };
}
