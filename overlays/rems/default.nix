{
  lib,
  stdenv,
  fetchFromGitHub,
  swift,
  swiftpm,
  swiftpm2nix,
}:
let
  generated = swiftpm2nix.helpers ./generated;
in
stdenv.mkDerivation rec {
  pname = "rems";
  version = "0-unstable";

  src = fetchFromGitHub {
    owner = "ivankovnatsky";
    repo = "rems";
    rev = "9b3940b";
    hash = "sha256-AdgyQtsih9+dKJvAKcVlFKXFI5gsJVPuOutXb06Hj/I=";
  };

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  # Remove @retroactive annotations that require Swift 6.x
  postPatch = ''
    substituteInPlace Sources/RemsLibrary/EKReminder+Encodable.swift \
      --replace-fail '@retroactive Encodable' 'Encodable'
    substituteInPlace Sources/RemsLibrary/NaturalLanguage.swift \
      --replace-fail '@retroactive ExpressibleByArgument' 'ExpressibleByArgument'
  '';

  configurePhase = generated.configure;

  swiftpmFlags = [ "--product rems" ];

  installPhase = ''
    binPath="$(swiftpmBinPath)"
    mkdir -p $out/bin
    cp $binPath/rems $out/bin/
  '';

  meta = with lib; {
    description = "A command-line tool for interacting with macOS Reminders";
    homepage = "https://github.com/ivankovnatsky/rems";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "rems";
  };
}
