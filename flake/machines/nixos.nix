{ makeNixosConfig, makeStableNixosConfig }:
{
  # Using stable NixOS 24.11 for the headless server
  "beelink" = makeStableNixosConfig {
    hostname = "beelink";
    system = "x86_64-linux";
    username = "ivan";
    modules = [
      {
        networking.hostName = "beelink";
        users.users.ivan.home = "/home/ivan";
        system.stateVersion = "24.11";
      }
    ];
  };
}
