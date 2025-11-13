{ lib
, rustPlatform
, fetchFromGitHub
,
}:

rustPlatform.buildRustPackage rec {
  pname = "bin";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "w4";
    repo = "bin";
    rev = "v${version}";
    hash = "sha256-FO5RiprLLtVd9Dle7at66pU3v7pb2IIWAfqFDl06AFY=";
  };

  cargoHash = "sha256-GIle7p1W9JPIHrVxHXbZnkdMFtsXzklTi5B1/YvaWD4=";

  meta = with lib; {
    description = "A paste bin that's actually minimalist";
    homepage = "https://github.com/w4/bin";
    license = with licenses; [
      bsd0
      wtfpl
    ];
    maintainers = [ ivankovnatsky ];
    mainProgram = "bin";
  };
}
