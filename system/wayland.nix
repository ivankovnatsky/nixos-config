{ pkgs, ... }:

{
  imports = [
    ./greetd.nix
  ];

  security = {
    pam.services.swaylock = { };
  };
}
