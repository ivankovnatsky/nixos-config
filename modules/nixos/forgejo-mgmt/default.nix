{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.forgejo-mgmt;

  configJson = pkgs.writeText "forgejo-mgmt-config.json" (
    builtins.toJSON {
      inherit (cfg) baseUrl;
      inherit (cfg) forgejoBin;
      inherit (cfg) configFile;
      inherit (cfg) workPath;
      inherit (cfg) tokenFile;
      inherit (cfg) users;
      inherit (cfg) repositories;
    }
  );

  userSubmodule = types.submodule {
    options = {
      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Username (use usernameFile for secret-based usernames)";
      };

      usernameFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing the username";
      };

      emailFile = mkOption {
        type = types.str;
        description = "Path to file containing email address";
      };

      passwordFile = mkOption {
        type = types.str;
        description = "Path to file containing password";
      };

      admin = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this user is an admin";
      };

      createToken = mkOption {
        type = types.bool;
        default = false;
        description = "Create an access token for this user and print it in logs";
      };

      gpgKeyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing armored GPG public key to upload to Forgejo";
      };
    };
  };
in
{
  options.local.services.forgejo-mgmt = {
    enable = mkEnableOption "declarative Forgejo user and repository management";

    forgejoBin = mkOption {
      type = types.str;
      default = "${pkgs.forgejo}/bin/forgejo";
      defaultText = literalExpression ''"''${pkgs.forgejo}/bin/forgejo"'';
      description = "Path to the forgejo binary used for offline admin commands.";
    };

    configFile = mkOption {
      type = types.str;
      description = "Path to the Forgejo app.ini config file";
    };

    workPath = mkOption {
      type = types.str;
      description = "Forgejo working directory (FORGEJO_WORK_DIR)";
    };

    baseUrl = mkOption {
      type = types.str;
      default = "http://localhost:3300";
      description = "Forgejo base URL for API calls";
    };

    users = mkOption {
      type = types.listOf userSubmodule;
      default = [ ];
      description = "Users to create on the Forgejo instance. The first admin user is used for API operations.";
    };

    tokenFile = mkOption {
      type = types.str;
      description = "Path to file where the admin API token is stored (created on first run)";
    };

    repositories = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Repository name";
            };

            owner = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Username who owns this repository (use ownerFile for secret-based)";
            };

            ownerFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Path to file containing the owner username";
            };

            description = mkOption {
              type = types.str;
              default = "";
              description = "Repository description";
            };

            private = mkOption {
              type = types.bool;
              default = true;
              description = "Whether the repository is private";
            };

            autoInit = mkOption {
              type = types.bool;
              default = false;
              description = "Initialize repository with a README";
            };
          };
        }
      );
      default = [ ];
      description = "Repositories to create on the Forgejo instance";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (builtins.filter (u: u.admin) cfg.users) != [ ];
        message = "forgejo-mgmt: at least one user must have admin = true";
      }
    ]
    ++ (map (u: {
      assertion = u.username != null || u.usernameFile != null;
      message = "forgejo-mgmt: each user must set either username or usernameFile";
    }) cfg.users)
    ++ (map (r: {
      assertion = r.owner != null || r.ownerFile != null;
      message = "forgejo-mgmt: each repository must set either owner or ownerFile";
    }) cfg.repositories);

    # Oneshot mirror of the mini's launchd job. Runs after forgejo.service is
    # active so the API socket exists; the forgejo-mgmt tool does its own HTTP
    # retries against baseUrl. Swallowing a non-zero exit (matching the mini's
    # `|| echo Warning`) avoids a hard activation failure if the API isn't
    # quite ready on the first boot — the unit will run again on next switch.
    systemd.services.forgejo-mgmt-sync = {
      description = "Forgejo declarative user and repository synchronization";
      wantedBy = [ "multi-user.target" ];
      after = [ "forgejo.service" ];
      wants = [ "forgejo.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Run as the forgejo system user (created by services.forgejo) so the
        # mgmt-token file and any sqlite writes done by `forgejo admin ...`
        # subprocesses land with the same ownership as the rest of stateDir.
        # Mirrors how the mini's launchd job runs as `ivan`, the data owner.
        User = "forgejo";
        Group = "forgejo";
        ExecStart = pkgs.writeShellScript "forgejo-mgmt-sync" ''
          set -e

          echo "Syncing Forgejo configuration..."
          ${pkgs.forgejo-mgmt}/bin/forgejo-mgmt sync \
            --config-file "${configJson}" 2>&1 || echo "Warning: Forgejo sync failed with exit code $?"

          echo "Forgejo configuration sync completed"
        '';
      };
    };
  };
}
