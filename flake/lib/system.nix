{ inputs, ... }:
{
  # Base module used across all configurations
  baseModule = { hostname }: [
    {
      imports = [ ../../machines/${hostname} ];
      nixpkgs.overlays = [ inputs.self.overlay ];
    }
    {
      nix.nixPath.nixpkgs = "${inputs.nixpkgs}";
    }
  ];
}
