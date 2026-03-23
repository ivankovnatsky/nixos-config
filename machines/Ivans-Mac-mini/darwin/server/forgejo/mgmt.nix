{ config, username, ... }:
{
  sops.secrets = {
    forgejo-admin-password = {
      key = "forgejo/admin/password";
      owner = username;
    };
    forgejo-admin-email = {
      key = "forgejo/admin/email";
      owner = username;
    };
  };

  local.services.forgejo-mgmt = {
    enable = true;

    configFile = "${config.flags.externalStoragePath}/.forgejo/app.ini";
    workPath = "${config.flags.externalStoragePath}/.forgejo";
    baseUrl = "http://${config.flags.machineLocalAddress}:3300";

    adminUser = {
      username = "forgejo";
      emailFile = config.sops.secrets.forgejo-admin-email.path;
      passwordFile = config.sops.secrets.forgejo-admin-password.path;
    };

    tokenFile = "${config.flags.externalStoragePath}/.forgejo/mgmt-token";

    # repositories = [
    #   {
    #     name = "notes";
    #     description = "Personal notes";
    #     private = true;
    #   }
    # ];
  };
}
