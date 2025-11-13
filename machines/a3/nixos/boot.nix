{ config
, lib
, pkgs
, ...
}:

{
  # Always use at least 1 second timeout to be able to boot from prev nix generation in case of nuclear war
  boot.loader.timeout = 1;
}
