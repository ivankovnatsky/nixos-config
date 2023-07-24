{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python
    python310
    python310Packages.pip
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
