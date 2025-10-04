{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:

let
  version = "3.7.0";

  # Platform-specific URLs and hashes
  sources = {
    aarch64-darwin = {
      url = "https://github.com/slackapi/slack-cli/releases/download/v${version}/slack_cli_${version}_macOS_arm64.tar.gz";
      hash = "sha256-spHI8S8+BJjo3Rs3fXfLAPvYfeBKSt73Ot3yXn3dsYE=";
    };
    x86_64-darwin = {
      url = "https://github.com/slackapi/slack-cli/releases/download/v${version}/slack_cli_${version}_macOS_amd64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Replace with actual hash
    };
    x86_64-linux = {
      url = "https://github.com/slackapi/slack-cli/releases/download/v${version}/slack_cli_${version}_linux_64-bit.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Replace with actual hash
    };
  };

  sourceInfo =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation rec {
  pname = "slack-cli-go";
  inherit version;

  src = fetchurl {
    inherit (sourceInfo) url hash;
  };

  nativeBuildInputs = [ installShellFiles ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 bin/slack $out/bin/slack

    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line interface for building apps on the Slack Platform";
    homepage = "https://github.com/slackapi/slack-cli";
    license = licenses.asl20;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "slack";
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
