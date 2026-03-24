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
    # Export with: gpg --armor --export <KEY_ID> | pbcopy
    # Then in sops: forgejo/users/swedishunhorned/gpgPublicKey: |
    #   -----BEGIN PGP PUBLIC KEY BLOCK-----
    #   ...
    forgejo-user-gpg-key = {
      key = "forgejo/users/swedishunhorned/gpgPublicKey";
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
        createToken = true;
        emailFile = config.sops.secrets.forgejo-user-email.path;
        passwordFile = config.sops.secrets.forgejo-user-password.path;
        gpgKeyFile = config.sops.secrets.forgejo-user-gpg-key.path;
      }
    ];

    tokenFile = "${config.flags.externalStoragePath}/.forgejo/mgmt-token";

    repositories = [
      {
        name = "notes";
        owner = "swedishunhorned";
        description = "";
        private = true;
      }
    ];
  };
}
