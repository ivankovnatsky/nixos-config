{ lib
, buildGoModule
, makeWrapper
, imagemagick
, exiftool
,
}:
buildGoModule {
  pname = "convert-to-jpg";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/convert-to-jpg \
      --prefix PATH : ${lib.makeBinPath [ imagemagick exiftool ]}
  '';

  meta = with lib; {
    description = "Convert images to JPG format with parallel processing";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "convert-to-jpg";
  };
}
