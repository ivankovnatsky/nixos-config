{ lib
, buildGo125Module
, fetchFromGitHub
, ffmpeg
, yt-dlp
,
}:
buildGo125Module rec {
  pname = "podsync";
  version = "unstable-2025-10-09";

  src = fetchFromGitHub {
    owner = "mxpv";
    repo = "podsync";
    rev = "0f37520c272c10e1c340a58dea1b2bf9ca1d9b37";
    hash = "sha256-jCQRdHhZcGSKJDH2bfCJqZd+FQUWYrTnXFHOF5i6o0A=";
  };

  vendorHash = "sha256-KyWE/1bGJHrSy0knuNM0or9VNYWdPo76vtTtkeMoTpI=";

  subPackages = [ "cmd/podsync" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
    "-X main.commit=${src.rev}"
  ];

  tags = [ "netgo" ];

  meta = with lib; {
    description = "Turn YouTube or Vimeo channels into podcast feeds";
    homepage = "https://github.com/mxpv/podsync";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "podsync";
  };
}
