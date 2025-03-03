{ inputs, ... }:
{
  inherit (import ./system.nix { inherit inputs; }) systemModule;
  inherit (import ./nixos.nix { inherit inputs; })
    makeBaseNixosSystem
    makeNixosWithHome
    makeNixosConfig
    ;
  inherit (import ./home.nix { inherit inputs; }) homeManagerModule;
  inherit (import ./darwin.nix { inherit inputs; })
    darwinHomebrewModule
    makeBaseDarwinSystem
    makeBaseDarwinWithHome
    makeFullDarwinConfig
    ;
}
