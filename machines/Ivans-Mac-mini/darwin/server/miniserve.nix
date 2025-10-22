{
  config,
  pkgs,
  ...
}:

let
  authFile = pkgs.writeText "miniserve-auth" "${config.secrets.miniserve.mini.username}:${config.secrets.miniserve.mini.password}";
in
{
  local.launchd.services.miniserve = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    command = ''
      ${pkgs.miniserve}/bin/miniserve \
        --interfaces 127.0.0.1 \
        --interfaces ::1 \
        --interfaces ${config.flags.miniIp} \
        --auth-file ${authFile} \
        ${config.flags.miniStoragePath}
    '';
  };
}
