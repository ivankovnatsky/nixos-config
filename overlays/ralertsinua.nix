{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "ralertsinua";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "voiceapiai";
    repo = "ralertsinua";
    rev = "v${version}";
    # sha256 = "0000000000000000000000000000000000000000000000000000000000000000";
    hash = "sha256-p8jrLviOywObpARSo0ygzhiEU8tZOEBCujNY+kzcx6U=";
  };

  cargoHash = "sha256-ZPSvGI0+HlpdoVx1OhyCh1Luh647VwUaUh6Iz+lYmQs=";
  # cargoSha256 = "0000000000000000000000000000000000000000000000000000000000000000";

  meta = {
    mainProgram = "ralertsinua";
    homepage = "https://github.com/voiceapiai/ralertsinua";
    description = "Rust async API wrapper (reqwest) & TUI (ratatui) for Air Raid Alert Map of Ukraine";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ivankovnatsky ];
  };
}
