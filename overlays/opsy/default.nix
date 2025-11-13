{ lib
, stdenv
, fetchurl
, installShellFiles
,
}:

stdenv.mkDerivation rec {
  pname = "opsy";
  version = "0.0.1";

  src = fetchurl {
    url = "https://github.com/datolabs-io/opsy/releases/download/v${version}/opsy_Darwin_arm64.tar.gz";
    sha256 = "sha256-HDVUzAJkaOLhWGy8IyXhjdbk5L4cZ83NPh4E5daq0ow=";
  };

  nativeBuildInputs = [ installShellFiles ];

  sourceRoot = ".";

  installPhase = ''
    install -D ./opsy $out/bin/opsy

    # Generate and install shell completions if available
    if [ -f ./completions/opsy.bash ]; then
      installShellCompletion --bash ./completions/opsy.bash
    fi
    if [ -f ./completions/opsy.fish ]; then
      installShellCompletion --fish ./completions/opsy.fish
    fi
    if [ -f ./completions/opsy.zsh ]; then
      installShellCompletion --zsh ./completions/opsy.zsh
    fi
  '';

  meta = with lib; {
    description = "Opsy - Your AI-Powered SRE Colleague";
    homepage = "https://github.com/datolabs-io/opsy";
    license = licenses.asl20; # Apache License 2.0
    maintainers = with maintainers; [ ivankovnatsky ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "opsy";
  };
}
