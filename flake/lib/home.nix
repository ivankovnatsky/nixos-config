{ inputs, ... }:
{
  # Home-manager base configuration
  homeManagerModule =
    {
      hostname,
      username,
      extraImports ? [ ],
    }:
    [
      inputs.home-manager.darwinModules.home-manager
      (
        { config, system, ... }:
        {
          nix.nixPath.nixpkgs = "${inputs.nixpkgs}";

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = {
              imports = [
                ../../machines/${hostname}/home.nix
                {
                  programs.home-manager.enable = true;
                }
              ] ++ extraImports;
            };

            extraSpecialArgs = {
              inherit inputs system username;
              super = config;
            };
          };
        }
      )
    ];
}
