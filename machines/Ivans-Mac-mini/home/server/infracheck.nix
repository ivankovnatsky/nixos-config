{
  config,
  pkgs,
  ...
}:

let
  configFile = pkgs.writeText "infracheck-config.json" (
    builtins.toJSON {
      discordWebhookFile = config.sops.secrets.discord-webhook-infracheck.path;
      checks = [
        {
          name = "taskwarrior-orphans";
          type = "taskwarrior-orphans";
          options = {
            database = "${config.home.homeDirectory}/.task/taskchampion.sqlite3";
          };
        }
        {
          name = "taskwarrior-sync-backlog";
          type = "taskwarrior-sync";
          options = {
            database = "${config.home.homeDirectory}/.task/taskchampion.sqlite3";
            threshold = 500;
          };
        }
      ];
    }
  );
in
{
  sops.secrets.discord-webhook-infracheck = {
    key = "discord/webhooks/monitoringInfraCheck";
  };

  local.launchd.services.infracheck = {
    enable = true;
    command = "${pkgs.infracheck}/bin/infracheck --config ${configFile}";
    waitForSecrets = true;
    keepAlive = false;
    runAtLoad = false;
    extraServiceConfig = {
      StartCalendarInterval = [
        { Minute = 0; }
      ];
    };
  };
}
