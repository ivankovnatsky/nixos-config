{ inputs, ... }:
{
  "bee" = inputs.nixpkgs-nixos-release.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/bee

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixpkgs-nixos-release}"
          "nixos-release=${inputs.nixpkgs-nixos-release}"
        ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "bee";
        users.users.ivan.home = "/home/ivan";
        system.stateVersion = "24.11";
      }
    ];
    specialArgs = {
      system = "x86_64-linux";
      username = "ivan";
    };
  };

  "a3" = inputs.nixpkgs-nixos-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/a3

      # Basic system configuration
      {
        nixpkgs.overlays = [
          inputs.self.overlay
          inputs.nur.overlay
        ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixpkgs-nixos-unstable}"
          "nixpkgs-nixos-unstable=${inputs.nixpkgs-nixos-unstable}"
        ];
        _module.args = {
          flake-inputs = inputs;
        };

        # System settings
        networking.hostName = "a3";
        users.users.ivan.home = "/home/ivan";
      }

      # Home Manager module
      inputs.home-manager-nixos-unstable.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          users.ivan = {
            imports = [
              ../../machines/a3/home
              inputs.nixvim-nixos-unstable.homeModules.nixvim
              inputs.plasma-manager-nixos-unstable.homeModules.plasma-manager
            ];
          };
          extraSpecialArgs = {
            inherit inputs;
            system = "x86_64-linux";
            username = "ivan";
          };
          sharedModules = [
            {
              home.stateVersion = "25.05";
            }
          ];
        };
      }
    ];
    specialArgs = {
      system = "x86_64-linux";
      username = "ivan";
    };
  };
}
