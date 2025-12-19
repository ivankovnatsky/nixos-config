{
  config,
  pkgs,
  username,
  ...
}:

{
  sops.secrets.miniserve-username = {
    key = "miniserve/mini/username";
    owner = username;
  };

  sops.secrets.miniserve-password = {
    key = "miniserve/mini/password";
    owner = username;
  };

  sops.templates."miniserve-auth" = {
    content = ''
      ${config.sops.placeholder.miniserve-username}:${config.sops.placeholder.miniserve-password}
    '';
    owner = username;
  };

  local.launchd.services.miniserve = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    command = ''
      ${pkgs.miniserve}/bin/miniserve \
        --interfaces 127.0.0.1 \
        --interfaces ::1 \
        --interfaces ${config.flags.miniIp} \
        --auth-file ${config.sops.templates."miniserve-auth".path} \
        ${config.flags.miniStoragePath}
    '';
  };
}
