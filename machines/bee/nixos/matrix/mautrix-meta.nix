{ config, pkgs, ... }:
{
  # Sops secrets for Matrix bridge
  sops.secrets.external-domain = {
    key = "externalDomain";
  };

  sops.secrets.matrix-username = {
    key = "matrix/username";
  };

  # Create environment file from sops secrets for mautrix-meta
  sops.templates."mautrix-meta.env".content = ''
    EXTERNAL_DOMAIN=${config.sops.placeholder."external-domain"}
    MATRIX_USERNAME=${config.sops.placeholder."matrix-username"}
  '';

  services.mautrix-meta = {
    package = pkgs.nixpkgs-nixos-unstable.mautrix-meta;

    instances = {
      messenger = {
        enable = true;

        registerToSynapse = true;

        # Load secrets from sops-generated environment file
        environmentFile = config.sops.templates."mautrix-meta.env".path;

        settings = {
          network.mode = "messenger";

          homeserver = {
            address = "http://${config.flags.beeIp}:8008";
            # Using environment variable from sops template
            domain = "matrix.$EXTERNAL_DOMAIN";
          };

          appservice = {
            id = "messenger";
            address = "http://127.0.0.1:29322";
            hostname = "127.0.0.1";
            port = 29322;

            bot = {
              username = "facebookbot";
              displayname = "Messenger bridge bot";
              avatar = "mxc://maunium.net/ygtkteZsXnGJLJHRchUwYWak";
            };

            username_template = "facebook_{{.}}";
          };

          database = {
            type = "sqlite3-fk-wal";
            uri = "file:/var/lib/mautrix-meta-messenger/mautrix-meta.db?_txlock=immediate";
          };

          bridge = {
            permissions = {
              # Using environment variables from sops template
              "@$MATRIX_USERNAME:matrix.$EXTERNAL_DOMAIN" = "admin";
              "*" = "relay";
            };
          };
        };
      };

      instagram = {
        enable = true;

        registerToSynapse = true;

        # Load secrets from sops-generated environment file
        environmentFile = config.sops.templates."mautrix-meta.env".path;

        settings = {
          network.mode = "instagram";

          homeserver = {
            address = "http://${config.flags.beeIp}:8008";
            # Using environment variable from sops template
            domain = "matrix.$EXTERNAL_DOMAIN";
          };

          appservice = {
            id = "instagram";
            address = "http://127.0.0.1:29320";
            hostname = "127.0.0.1";
            port = 29320;

            bot = {
              username = "instagrambot";
              displayname = "Instagram bridge bot";
              avatar = "mxc://maunium.net/JxjlbZUlCPULEeHZSwleUXQv";
            };

            username_template = "instagram_{{.}}";
          };

          database = {
            type = "sqlite3-fk-wal";
            uri = "file:/var/lib/mautrix-meta-instagram/mautrix-meta.db?_txlock=immediate";
          };

          bridge = {
            permissions = {
              # Using environment variables from sops template
              "@$MATRIX_USERNAME:matrix.$EXTERNAL_DOMAIN" = "admin";
              "*" = "relay";
            };
          };
        };
      };
    };
  };
}
