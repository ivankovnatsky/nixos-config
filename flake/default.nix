{ inputs, ... }:
let
  lib = import ./lib { inherit inputs; };
  machines = import ./machines.nix;
in
{
  inherit lib;
  darwinConfigurations = machines.darwinConfigurations { inherit (lib) makeFullDarwinConfig; };
  overlay = import ./overlay.nix { inherit inputs; };
}
