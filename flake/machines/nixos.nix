{ makeNixosConfig, makeStableNixosConfig }:
{
  # Using stable NixOS 24.11 for the headless server
  "bee" = makeStableNixosConfig {
    hostname = "bee";
    system = "x86_64-linux";
    username = "ivan";
    modules = [
      {
        networking.hostName = "bee";
        users.users.ivan.home = "/home/ivan";
        system.stateVersion = "24.11";
      }
    ];
  };
}
