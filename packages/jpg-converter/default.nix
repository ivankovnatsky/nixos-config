{
  lib,
  buildGoModule,
  makeWrapper,
  imagemagick,
  exiftool,
}:
buildGoModule {
  pname = "jpg-converter";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/jpg-converter \
      --prefix PATH : ${lib.makeBinPath [ imagemagick exiftool ]}
  '';

  meta = with lib; {
    description = "Convert images to JPG format with parallel processing";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "jpg-converter";
  };
}
