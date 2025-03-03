{ inputs, ... }:
let
  lib = import ./lib { inherit inputs; };
  machines = import ./machines;
in
{
  inherit lib;
  darwinConfigurations = machines.darwinConfigurations { inherit (lib) makeFullDarwinConfig; };
  nixosConfigurations = machines.nixosConfigurations { inherit (lib) makeNixosConfig; };
  overlay = import ./overlay.nix { inherit inputs; };
}
