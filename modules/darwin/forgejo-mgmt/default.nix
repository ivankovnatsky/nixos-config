{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.forgejo-mgmt;

  configJson = pkgs.writeText "forgejo-mgmt-config.json" (builtins.toJSON {
    baseUrl = cfg.baseUrl;
    forgejoBin = "${cfg.forgejoPackage}/bin/forgejo";
    configFile = cfg.configFile;
    workPath = cfg.workPath;
    tokenFile = cfg.tokenFile;
    adminUser = {
      inherit (cfg.adminUser) username;
      inherit (cfg.adminUser) emailFile;
      inherit (cfg.adminUser) passwordFile;
    };
    repositories = cfg.repositories;
  });
in
{
  options.local.services.forgejo-mgmt = {
    enable = mkEnableOption "declarative Forgejo admin user and repository management";

    forgejoPackage = mkPackageOption pkgs "forgejo" { };

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

    adminUser = {
      username = mkOption {
        type = types.str;
        default = "forgejo";
        description = "Admin username";
      };

      emailFile = mkOption {
        type = types.str;
        description = "Path to file containing admin email address";
      };

      passwordFile = mkOption {
        type = types.str;
        description = "Path to file containing admin password";
      };
    };

    tokenFile = mkOption {
      type = types.str;
      description = "Path to file where the admin API token is stored (created on first run)";
    };

    repositories = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Repository name";
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
      });
      default = [ ];
      description = "Repositories to create on the Forgejo instance";
    };
  };

  config = mkIf cfg.enable {
    local.launchd.services.forgejo-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;
      waitForSecrets = true;

      command =
        let
          syncScript = pkgs.writeShellScript "forgejo-mgmt-sync" ''
            set -e

            echo "Syncing Forgejo configuration..."
            ${pkgs.forgejo-mgmt}/bin/forgejo-mgmt sync \
              --config-file "${configJson}" 2>&1 || echo "Warning: Forgejo sync failed with exit code $?"

            echo "Forgejo configuration sync completed"
          '';
        in
        "${syncScript}";
    };
  };
}
