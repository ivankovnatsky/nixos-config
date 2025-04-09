{ inputs, ... }:
let
  machines = import ./machines { inherit inputs; };
in
{
  inherit (machines) darwinConfigurations nixosConfigurations;
  overlay = import ./overlay.nix { inherit inputs; };
}
