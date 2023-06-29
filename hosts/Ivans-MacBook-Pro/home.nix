{ pkgs, ... }:

{
  imports = [
    ../../home/transmission.nix
    ../../home/workstation.nix
  ];

  home.packages = with pkgs; [
    aria
    defaultbrowser
    typst
    rustc
    nixpkgs-unstable-pin.killport

    # Rust build
    openssl
    libiconv
    pkg-config
    cmake
    zlib
    darwin.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
    cyrus_sasl
  ];
}
