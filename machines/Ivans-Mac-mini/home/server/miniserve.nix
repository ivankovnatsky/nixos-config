{
  config,
  pkgs,
  ...
}:

{
  sops = {
    secrets = {
      miniserve-username = {
        key = "miniserve/mini/username";
      };

      miniserve-password = {
        key = "miniserve/mini/password";
      };
    };

    templates."miniserve-auth" = {
      content = ''
        ${config.sops.placeholder.miniserve-username}:${config.sops.placeholder.miniserve-password}
      '';
    };
  };

  local.launchd.services.miniserve = {
    enable = true;
    waitForPath = config.flags.externalStoragePath;
    command = ''
      ${pkgs.miniserve}/bin/miniserve \
        --interfaces 127.0.0.1 \
        --interfaces ::1 \
        --interfaces ${config.flags.machineBindAddress} \
        --auth-file ${config.sops.templates."miniserve-auth".path} \
        --upload-files /Backup/Machines \
        --mkdir \
        --on-duplicate-files rename \
        ${config.flags.externalStoragePath}
    '';
  };
}
