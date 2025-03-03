{ inputs, ... }:

{
  # Base module used across all configurations
  systemModule =
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
