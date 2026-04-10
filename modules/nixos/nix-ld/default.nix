# nix-ld support for dynamically linked binaries (npm/bun packages, etc.)
{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
    nodejs
  ];
}
