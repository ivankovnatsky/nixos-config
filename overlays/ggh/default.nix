{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ggh";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "byawitz";
    repo = "ggh";
    rev = "v${version}";
    hash = "sha256-itNx/AcLUQCH99ZCOXiXPWNg3mx+UhHepidqmzPY8Oc=";
  };

  vendorHash = "sha256-WPPjpxCD3WA3E7lx5+DPvG31p8djera5xRn980eaJT8=";

  meta = with lib; {
    description = "Recall your SSH sessions";
    homepage = "https://github.com/byawitz/ggh";
    license = licenses.asl20;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "ggh";
  };
}
