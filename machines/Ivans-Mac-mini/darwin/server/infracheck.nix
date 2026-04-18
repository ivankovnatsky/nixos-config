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
            database = "/Users/ivan/.task/taskchampion.sqlite3";
          };
        }
        {
          name = "taskwarrior-sync-backlog";
          type = "taskwarrior-sync";
          options = {
            database = "/Users/ivan/.task/taskchampion.sqlite3";
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
    mode = "0444";
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
