{
  config,
  pkgs,
  ...
}:

{
  sops.secrets.miniserve-username = {
    key = "miniserve/mini/username";
  };

  sops.secrets.miniserve-password = {
    key = "miniserve/mini/password";
  };

  sops.templates."miniserve-auth".content = ''
    ${config.sops.placeholder.miniserve-username}:${config.sops.placeholder.miniserve-password}
  '';

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
