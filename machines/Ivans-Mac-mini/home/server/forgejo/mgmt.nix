{ config, ... }:
{
  sops.secrets = {
    forgejo-admin-name = {
      key = "forgejo/users/forgejoAdmin/name";
    };
    forgejo-admin-password = {
      key = "forgejo/users/forgejoAdmin/password";
    };
    forgejo-admin-email = {
      key = "forgejo/users/forgejoAdmin/email";
    };
    forgejo-user-name = {
      key = "forgejo/users/forgejoUser/name";
    };
    forgejo-user-password = {
      key = "forgejo/users/forgejoUser/password";
    };
    forgejo-user-email = {
      key = "forgejo/users/forgejoUser/email";
    };
    # Export with: gpg --armor --export <KEY_ID> | pbcopy
    # Then in sops: forgejo/users/forgejoUser/gpgPublicKey: |
    #   -----BEGIN PGP PUBLIC KEY BLOCK-----
    #   ...
    forgejo-user-gpg-key = {
      key = "forgejo/users/forgejoUser/gpgPublicKey";
    };
  };

  local.services.forgejo-mgmt = {
    enable = true;

    configFile = "${config.flags.externalStoragePath}/.forgejo/app.ini";
    workPath = "${config.flags.externalStoragePath}/.forgejo";
    baseUrl = "http://${config.flags.machineLocalAddress}:3300";

    users = [
      {
        usernameFile = config.sops.secrets.forgejo-admin-name.path;
        admin = true;
        emailFile = config.sops.secrets.forgejo-admin-email.path;
        passwordFile = config.sops.secrets.forgejo-admin-password.path;
      }
      {
        usernameFile = config.sops.secrets.forgejo-user-name.path;
        createToken = true;
        emailFile = config.sops.secrets.forgejo-user-email.path;
        passwordFile = config.sops.secrets.forgejo-user-password.path;
        gpgKeyFile = config.sops.secrets.forgejo-user-gpg-key.path;
      }
    ];

    tokenFile = "${config.flags.externalStoragePath}/.forgejo/mgmt-token";

    repositories = [
      {
        name = "home";
        ownerFile = config.sops.secrets.forgejo-user-name.path;
        description = "Home directory";
        private = true;
      }
      {
        name = "notes";
        ownerFile = config.sops.secrets.forgejo-user-name.path;
        description = "";
        private = true;
      }
      {
        name = "workspace";
        ownerFile = config.sops.secrets.forgejo-user-name.path;
        description = "OpenClaw agent workspace";
        private = true;
      }
    ];
  };
}
