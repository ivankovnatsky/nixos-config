{ pkgs, ... }:

let
  # Declarative list of Steam games managed via steamcmd.
  # Synced via systemd user service on login.
  # Run `steam-mgmt sync --dry-run` to preview changes.
  games = [
    {
      appId = "24780";
      name = "SimCity 4 Deluxe";
      anonymous = false;
    }
    {
      appId = "255710";
      name = "Cities: Skylines";
      anonymous = false;
    }
    {
      appId = "1084020";
      name = "TheoTown";
      anonymous = false;
    }
    {
      appId = "1091500";
      name = "Cyberpunk 2077";
      anonymous = false;
    }
    {
      appId = "1245620";
      name = "ELDEN RING";
      anonymous = false;
    }
    {
      appId = "1259980";
      name = "RIDE 4";
      anonymous = false;
    }
    {
      appId = "1432320";
      name = "Liftoff: Micro Drones";
      anonymous = false;
    }
    {
      appId = "1593500";
      name = "God of War";
      anonymous = false;
    }
    {
      appId = "1627720";
      name = "Lies of P";
      anonymous = false;
    }
    {
      appId = "2001120";
      name = "Split Fiction";
      anonymous = false;
    }
    {
      appId = "2358720";
      name = "Black Myth: Wukong";
      anonymous = false;
    }
    {
      appId = "2377280";
      name = "Eriksholm: The Stolen Dream";
      anonymous = false;
    }
  ];

  manifest = builtins.toJSON games;
in
{
  home.packages = [ pkgs.steam-mgmt ];

  # Declarative game manifest for steam-mgmt sync
  home.file.".local/state/steam-mgmt/games.json".text = manifest;

  # Sync games after home-manager activation via systemd
  systemd.user.services.steam-sync = {
    Unit = {
      Description = "Sync Steam games from declarative manifest";
      After = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.steam-mgmt}/bin/steam-mgmt sync --yes";
      TimeoutStartSec = 0;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
