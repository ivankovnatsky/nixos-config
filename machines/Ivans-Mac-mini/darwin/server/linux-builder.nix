{ config, ... }:
{
  local.linux-builder = {
    # TODO: Private key disappears from /etc/nix/ during activation,
    # possibly cleaned by Determinate Nix. Needs investigation.
    enable = false;
    workingDirectory = "${config.flags.externalStoragePath}/.linux-builder";
  };
}
