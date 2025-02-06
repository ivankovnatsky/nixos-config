let
  mkDarwinConfigurations = { makeFullDarwinConfig }: {
    "Ivans-MacBook-Pro" = makeFullDarwinConfig {
      hostname = "Ivans-MacBook-Pro";
      system = "aarch64-darwin";
      username = "ivan";
      modules = [
        {
          networking.hostName = "Ivans-MacBook-Pro";
          users.users.ivan.home = "/Users/ivan";
        }
      ];
      homeModules = [
        ({ username, ... }: {
          home.username = "${username}";
          home.stateVersion = "23.11";
        })
      ];
    };

    "Ivans-MacBook-Air" = makeFullDarwinConfig {
      hostname = "Ivans-MacBook-Air";
      system = "aarch64-darwin";
      username = "ivan";
      modules = [
        ({ username, ... }: {
          networking.hostName = "Ivans-MacBook-Air";
          users.users.${username}.home = "/Users/${username}";
        })
      ];
      homeModules = [
        ({ username, ... }: {
          home.username = "${username}";
          home.stateVersion = "22.05";
        })
      ];
    };

    "Lusha-Macbook-Ivan-Kovnatskyi" = makeFullDarwinConfig {
      hostname = "Lusha-Macbook-Ivan-Kovnatskyi";
      system = "aarch64-darwin";
      username = "Ivan.Kovnatskyi";
      modules = [
        ({ username, ... }: {
          # Kandji sets it automatically, kept for reference.
          # networking.hostName = "Lusha-Macbook-Ivan-Kovnatskyi";
          users.users.${username}.home = "/Users/${username}";
        })
      ];
      homeModules = [
        ({ username, ... }: {
          home.username = "${username}";
          home.stateVersion = "24.05";
        })
      ];
    };
  };
in
{
  darwinConfigurations = mkDarwinConfigurations;
}
