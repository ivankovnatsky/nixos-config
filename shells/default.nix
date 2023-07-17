{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Ansible project deps
    python310
    python310Packages.botocore
    python310Packages.boto3

    # Rust
    openssl
    libiconv
    pkg-config
    cmake
    zlib
    cyrus_sasl
  ]
  ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];
}
