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
  pname = "reminders-cli";
  version = "0-unstable";

  src = fetchFromGitHub {
    owner = "ivankovnatsky";
    repo = "reminders-cli";
    rev = "44ba65f";
    hash = "sha256-u7EzrJCp2qhfELt9o24RnDKEvtvpRsls6K8ZvbPj8MA=";
  };

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  # Remove @retroactive annotations that require Swift 6.x
  postPatch = ''
    substituteInPlace Sources/RemindersLibrary/EKReminder+Encodable.swift \
      --replace-fail '@retroactive Encodable' 'Encodable'
    substituteInPlace Sources/RemindersLibrary/NaturalLanguage.swift \
      --replace-fail '@retroactive ExpressibleByArgument' 'ExpressibleByArgument'
  '';

  configurePhase = generated.configure;

  swiftpmFlags = [ "--product reminders" ];

  installPhase = ''
    binPath="$(swiftpmBinPath)"
    mkdir -p $out/bin
    cp $binPath/reminders $out/bin/
  '';

  meta = with lib; {
    description = "A command-line tool for interacting with macOS Reminders";
    homepage = "https://github.com/keith/reminders-cli";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "reminders";
  };
}
