{ pkgs, ... }:

{
  nix = {
    autoOptimiseStore = true;
    gc.automatic = true;
    optimise.automatic = true;

    useSandbox = false;
  };
}
