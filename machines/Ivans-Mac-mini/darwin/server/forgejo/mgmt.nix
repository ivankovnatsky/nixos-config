{ config, username, ... }:
{
  sops.secrets = {
    forgejo-admin-password = {
      key = "forgejo/users/forgejo/password";
      owner = username;
    };
    forgejo-admin-email = {
      key = "forgejo/users/forgejo/email";
      owner = username;
    };
    forgejo-user-password = {
      key = "forgejo/users/swedishunhorned/password";
      owner = username;
    };
    forgejo-user-email = {
      key = "forgejo/users/swedishunhorned/email";
      owner = username;
    };
  };

  local.services.forgejo-mgmt = {
    enable = true;

    configFile = "${config.flags.externalStoragePath}/.forgejo/app.ini";
    workPath = "${config.flags.externalStoragePath}/.forgejo";
    baseUrl = "http://${config.flags.machineLocalAddress}:3300";

    users = [
      {
        username = "forgejo";
        admin = true;
        emailFile = config.sops.secrets.forgejo-admin-email.path;
        passwordFile = config.sops.secrets.forgejo-admin-password.path;
      }
      {
        username = "swedishunhorned";
        emailFile = config.sops.secrets.forgejo-user-email.path;
        passwordFile = config.sops.secrets.forgejo-user-password.path;
      }
    ];

    tokenFile = "${config.flags.externalStoragePath}/.forgejo/mgmt-token";

    # repositories = [
    #   {
    #     name = "notes";
    #     owner = "swedishunhorned";
    #     description = "Personal notes";
    #     private = true;
    #   }
    # ];
  };
}
