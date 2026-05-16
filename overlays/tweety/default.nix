{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
}:
let
  version = "2.2.3-unstable";
  rev = "dc158cbb86656bc732d4c3bf754dafca8a3c2e5d";

  src = fetchFromGitHub {
    owner = "pomdtr";
    repo = "tweety";
    inherit rev;
    hash = "sha256-Iq894VuzkT3ntxPYXc0jmY1ckjo1UgoXQANAc7KwTjs=";
  };

  extension = buildNpmPackage {
    pname = "tweety-extension";
    inherit version src;
    sourceRoot = "${src.name}/extension";

    npmDepsHash = "sha256-KJ00A56SlXNp9osBeIogpwzdzkAcwBIoGaayH3nDbi8=";

    MANIFEST_VERSION = "2.2.3";

    buildPhase = ''
      runHook preBuild
      npm run build
      npm run build:firefox
      npm run zip:firefox
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/chrome-mv3 $out/chrome
      cp dist/tweety-*-firefox.zip $out/firefox.zip
      runHook postInstall
    '';

    dontNpmPrune = true;
  };
in
buildGoModule {
  pname = "tweety";
  inherit version src;

  vendorHash = "sha256-2tDOyjnu3cVPDzwWRjV8VAtuKPRgBk2206nTgKiCgsQ=";

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    mkdir -p $out/share/extensions
    cp -r ${extension}/chrome $out/share/extensions/chrome
    cp ${extension}/firefox.zip $out/share/extensions/firefox.zip
  '';

  meta = {
    description = "An integrated terminal for your browser";
    homepage = "https://github.com/pomdtr/tweety";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.ivankovnatsky ];
    mainProgram = "tweety";
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
