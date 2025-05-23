{ inputs, ... }:
{
  "bee" = inputs.nixos-release.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      # Import machine-specific configuration
      ../../machines/bee

      # Basic system configuration
      {
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
        nix.nixPath = [
          "nixpkgs=${inputs.nixos-release}"
          "nixos-release=${inputs.nixos-release}"
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
}
