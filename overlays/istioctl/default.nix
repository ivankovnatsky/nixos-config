{ name
, version
, platform
, sha256

, stdenv
, fetchurl
, ...
}:

let url = "https://github.com/istio/istio/releases/download/${version}/istio-${version}-${platform}.tar.gz";

in
stdenv.mkDerivation {
  inherit name version;
  src = fetchurl { inherit url sha256; };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    mv istio-${version}/bin/istioctl $out/bin
  '';
}
