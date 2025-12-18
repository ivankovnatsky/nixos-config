{ config, pkgs, lib, ... }:

let
  wrapperScript = pkgs.writeShellScriptBin "uptime-kuma-mgmt" ''
    BASE_URL="http://${config.flags.miniIp}:3001"
    USERNAME=$(cat ${config.sops.secrets.uptime-kuma-username.path})
    PASSWORD=$(cat ${config.sops.secrets.uptime-kuma-password.path})

    exec ${pkgs.uptime-kuma-mgmt}/bin/uptime-kuma-mgmt "$@" \
      --base-url "$BASE_URL" \
      --username "$USERNAME" \
      --password "$PASSWORD"
  '';
in
{
  sops.secrets.uptime-kuma-username = {
    key = "uptimeKuma/username";
  };
  sops.secrets.uptime-kuma-password = {
    key = "uptimeKuma/password";
  };

  home.packages = [ wrapperScript ];
}
