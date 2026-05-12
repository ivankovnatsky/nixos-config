{ config, ... }:
{
  # Declarative admin/user/repo provisioning for the local Forgejo instance.
  # Mirrors machines/Ivans-Mac-mini/home/server/forgejo/mgmt.nix — same sops
  # keys, same user shape, same repo list. The NixOS variant of the
  # local.services.forgejo-mgmt module wraps the same forgejo-mgmt CLI in a
  # systemd oneshot ordered after forgejo.service.
  #
  # NB: `forgejo-user-name` is already declared by system/sops-secrets.nix
  # (imported by the a3 NixOS config), so don't redeclare it here.
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
    forgejo-user-password = {
      key = "forgejo/users/forgejoUser/password";
    };
    forgejo-user-email = {
      key = "forgejo/users/forgejoUser/email";
    };
    forgejo-user-gpg-key = {
      key = "forgejo/users/forgejoUser/gpgPublicKey";
    };
  };

  local.services.forgejo-mgmt = {
    enable = true;

    # Match the upstream module's stateDir defaults (StateDirectory=forgejo).
    configFile = "/var/lib/forgejo/custom/conf/app.ini";
    workPath = "/var/lib/forgejo";

    # Loopback because forgejo.service binds 0.0.0.0:3000 (upstream default)
    # and we don't need to ride the LAN for a same-host API call.
    baseUrl = "http://127.0.0.1:3000";

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

    tokenFile = "/var/lib/forgejo/mgmt-token";

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
    ];
  };
}
