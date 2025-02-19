{ inputs, ... }:
{
  # Base module used across all configurations
  baseModule =
    { hostname }:
    [
      {
        imports = [ ../../machines/${hostname} ];
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
      }
      {
        nix.nixPath.nixpkgs = "${inputs.nixpkgs}";
      }
    ];
}
