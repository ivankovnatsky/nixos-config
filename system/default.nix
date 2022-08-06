{ pkgs, ... }:

{
  imports = [
    ../modules/default.nix
    ../modules/secrets.nix
  ];

  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixUnstable;

    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
    '';
  };
}
