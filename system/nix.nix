{ ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;
  };
}
