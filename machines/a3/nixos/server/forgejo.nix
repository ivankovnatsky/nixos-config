{ config, ... }:

let
  # HTTP_PORT stays at upstream default (3000); only SSH needs an override
  # because OpenSSH on a3 owns port 22.
  sshPort = 2222;
in
{
  # Declarative admin/user/repo provisioning for the local Forgejo instance.
  # The NixOS variant of local.services.forgejo-mgmt wraps the forgejo-mgmt
  # CLI in a systemd oneshot ordered after forgejo.service.
  #
  # NB: `forgejo-user-name` is already declared by system/sops-secrets.nix
  # (imported by the a3 NixOS config), so don't redeclare it here.
  # forgejo-mgmt-sync.service runs as User=forgejo, so each secret must be
  # readable by the forgejo user. Default sops permissions (0400 root:root)
  # would block it — mirror the stash.nix pattern instead.
  sops.secrets = {
    forgejo-admin-name = {
      key = "forgejo/users/forgejoAdmin/name";
      owner = "forgejo";
      group = "forgejo";
    };
    forgejo-admin-password = {
      key = "forgejo/users/forgejoAdmin/password";
      owner = "forgejo";
      group = "forgejo";
    };
    forgejo-admin-email = {
      key = "forgejo/users/forgejoAdmin/email";
      owner = "forgejo";
      group = "forgejo";
    };
    forgejo-user-password = {
      key = "forgejo/users/forgejoUser/password";
      owner = "forgejo";
      group = "forgejo";
    };
    forgejo-user-email = {
      key = "forgejo/users/forgejoUser/email";
      owner = "forgejo";
      group = "forgejo";
    };
    forgejo-user-gpg-key = {
      key = "forgejo/users/forgejoUser/gpgPublicKey";
      owner = "forgejo";
      group = "forgejo";
    };
  };

  # External domain is a sops secret. Wrap it in templates so the rendered
  # values land in /run/secrets-rendered/* at activation, then point the
  # upstream module's `secrets` option (LoadCredential-based) at them. This
  # mirrors how http.nix/dns.nix consume the same secret on a3.
  sops.templates."forgejo-domain" = {
    content = "forgejo.${config.sops.placeholder.external-domain}";
    owner = "forgejo";
    restartUnits = [ "forgejo.service" ];
  };

  sops.templates."forgejo-root-url" = {
    content = "https://forgejo.${config.sops.placeholder.external-domain}/";
    owner = "forgejo";
    restartUnits = [ "forgejo.service" ];
  };

  services.forgejo = {
    enable = true;

    # stateDir defaults to /var/lib/forgejo — matching it activates the
    # upstream module's StateDirectory=forgejo (creates + chowns automatically).
    # Layout under /var/lib/forgejo:
    #   conf/   - app.ini + auto-generated SECRET_KEY/INTERNAL_TOKEN/JWT_SECRET
    #   custom/ - templates and overrides
    #   data/   - sqlite db, sessions, avatars, lfs
    #   log/    - logs
    #   repositories/ - git repo storage

    # SQLite, same as mini.
    database.type = "sqlite3";

    lfs.enable = true;

    settings = {
      server = {
        # DOMAIN / ROOT_URL / SSH_DOMAIN are pulled in from sops.templates via
        # services.forgejo.secrets below (the strings here would leak into
        # /nix/store via the rendered app.ini). The placeholders only need to
        # be non-empty to satisfy the module's setting validation; the LoadCre-
        # dential-backed env vars override them at runtime.
        DOMAIN = "_sops_placeholder";
        ROOT_URL = "_sops_placeholder";
        SSH_DOMAIN = "_sops_placeholder";

        # Forgejo's built-in SSH server on 2222 — OpenSSH owns 22 on a3.
        # SSH_PORT (clone-URL display) and SSH_LISTEN_PORT (actual bind port)
        # must both be set; otherwise SSH_LISTEN_PORT silently follows SSH_PORT.
        START_SSH_SERVER = true;
        SSH_PORT = sshPort;
        SSH_LISTEN_PORT = sshPort;
      };

      service = {
        DISABLE_REGISTRATION = true;
      };

      session = {
        # Behind Caddy (TLS terminated upstream) — flag the cookie as secure
        # so it's only sent over HTTPS. Upstream default is false.
        COOKIE_SECURE = true;
      };
    };

    # Override DOMAIN/ROOT_URL/SSH_DOMAIN from sops-rendered files at runtime.
    # Upstream's `secrets` option translates these into FORGEJO__server__*
    # env vars via systemd LoadCredential, and the environment-to-ini step
    # writes them into the live app.ini — keeping the external domain out of
    # /nix/store.
    # DOMAIN and SSH_DOMAIN have identical content, so they share one template.
    secrets.server = {
      DOMAIN = config.sops.templates."forgejo-domain".path;
      ROOT_URL = config.sops.templates."forgejo-root-url".path;
      SSH_DOMAIN = config.sops.templates."forgejo-domain".path;
    };
  };

  # Ensure sops has rendered the templates before forgejo starts (otherwise
  # LoadCredential races with sops-nix on first boot).
  systemd.services.forgejo = {
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
  };

  # Open HTTP (3000, upstream default) and 2222 (built-in SSH) on the firewall.
  # Caddy on a3 reverse-proxies https://forgejo.<externalDomain>/ → a3Ip:3000.
  networking.firewall.allowedTCPPorts = [
    config.services.forgejo.settings.server.HTTP_PORT
    sshPort
  ];

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
      {
        name = "workspace";
        ownerFile = config.sops.secrets.forgejo-user-name.path;
        description = "OpenClaw agent workspace";
        private = true;
      }
      {
        name = "data";
        ownerFile = config.sops.secrets.forgejo-user-name.path;
        description = "";
        private = true;
      }
    ];
  };
}
