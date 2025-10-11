{ config, pkgs, ... }:
{
  services.mautrix-meta = {
    package = pkgs.nixpkgs-unstable-nixos.mautrix-meta;

    instances = {
      messenger = {
        enable = true;

        registerToSynapse = true;

        settings = {
          network.mode = "messenger";

          homeserver = {
            address = "http://${config.flags.beeIp}:8008";
            domain = "matrix.${config.secrets.externalDomain}";
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
              "@${config.secrets.matrix.username}:matrix.${config.secrets.externalDomain}" = "admin";
              "*" = "relay";
            };
          };
        };
      };

      instagram = {
        enable = true;

        registerToSynapse = true;

        settings = {
          network.mode = "instagram";

          homeserver = {
            address = "http://${config.flags.beeIp}:8008";
            domain = "matrix.${config.secrets.externalDomain}";
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
              "@${config.secrets.matrix.username}:matrix.${config.secrets.externalDomain}" = "admin";
              "*" = "relay";
            };
          };
        };
      };
    };
  };
}
