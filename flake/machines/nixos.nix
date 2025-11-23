{ inputs, ... }:
{
  "a3" = inputs.nixpkgs-nixos-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/a3

      # SOPS secrets management
      inputs.sops-nix-nixos-unstable.nixosModules.sops
      ../../shared/sops-nix.nix

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
              inputs.sops-nix-nixos-unstable.homeManagerModules.sops
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

  "steamdeck" = inputs.nixpkgs-nixos-unstable.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/steamdeck

      # Jovian-NixOS modules for Steam Deck
      inputs.jovian-nixos-unstable.nixosModules.default

      # SOPS secrets management
      inputs.sops-nix-nixos-unstable.nixosModules.sops
      ../../shared/sops-nix.nix

      # Basic system configuration
      {
        nixpkgs.overlays = [
          # Use self.overlay but exclude mangohud (causes build issues on steamdeck)
          (final: prev:
            let
              baseOverlay = inputs.self.overlay final prev;
            in
            builtins.removeAttrs baseOverlay [ "mangohud" ]
          )
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
        networking.hostName = "steamdeck";
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
              ../../machines/steamdeck/home
              inputs.nixvim-nixos-unstable.homeModules.nixvim
              inputs.plasma-manager-nixos-unstable.homeModules.plasma-manager
              inputs.sops-nix-nixos-unstable.homeManagerModules.sops
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
