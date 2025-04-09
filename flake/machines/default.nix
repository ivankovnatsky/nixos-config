{ inputs, ... }:
{
  darwinConfigurations = import ./darwin.nix { inherit inputs; };
  nixosConfigurations = import ./nixos.nix { inherit inputs; };
}
