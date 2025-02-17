{ inputs, ... }:
{
  inherit (import ./system.nix { inherit inputs; }) baseModule;
  inherit (import ./home.nix { inherit inputs; }) homeManagerModule;
  inherit (import ./darwin.nix { inherit inputs; })
    darwinHomebrewModule
    makeBaseDarwinSystem
    makeBaseDarwinWithHome
    makeFullDarwinConfig
    ;
}
