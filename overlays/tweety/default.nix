{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "tweety";
  version = "2.1.10";

  src = let
    selectSystem = attrs: attrs.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
    
    sources = {
      x86_64-linux = {
        url = "https://github.com/pomdtr/tweety/releases/download/v${version}/tweety-${version}-linux_amd64.tar.gz";
        sha256 = "sha256-8T+Bg2LDBWyAvNRxDIbLG72EE4g4J6hzq9nNvKV4czY=";
      };
      aarch64-darwin = {
        url = "https://github.com/pomdtr/tweety/releases/download/v${version}/tweety-${version}-darwin_arm64.tar.gz";
        sha256 = "sha256-0ubtR67K/+S246PDWkIl/ABiAllXCjrjUgCvaBKOgdU=";
      };
    };
    
    source = selectSystem sources;
  in fetchurl {
    url = source.url;
    sha256 = source.sha256;
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin $out/share
    cp tweety $out/bin/
    cp -r extensions $out/share/
  '';

  meta = with lib; {
    description = "An integrated terminal for your browser";
    homepage = "https://github.com/pomdtr/tweety";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "tweety";
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
  };
}