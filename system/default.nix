{ pkgs, ... }:

{
  imports = [
    ../modules/default.nix
    ../modules/secrets.nix
  ];

  documentation = {
    enable = true;
    man.enable = true;
    info.enable = false;
  };

  environment = {
    variables = {
      TMUX = "/tmp/tmux-1000/default";
    };
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
