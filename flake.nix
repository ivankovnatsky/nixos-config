{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs: {
    nixosConfigurations = {
      thinkpad = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/thinkpad

          { nixpkgs.overlays = [ inputs.nur.overlay ]; }

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ivan = import ./hosts/thinkpad/home.nix;
          }
        ];
      };
    };

    darwinConfigurations = {
      "Ivans-MacBook-Pro" = inputs.darwin.lib.darwinSystem {
        modules = [
          ./hosts/macbook

          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ivan = import ./hosts/macbook/home.nix;
          }
        ];
      };

      "workbook" = inputs.darwin.lib.darwinSystem {
        modules = [
          ./hosts/workbook

          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ivan = import ./hosts/workbook/home.nix;
          }
        ];
      };
    };
  };
}
