{
  name,
  owner,
  repo,
  version,
  platform,
  sha256,

  stdenv,
  fetchurl,
  unzip,
  ...
}:

let
  url = "https://github.com/${owner}/${repo}/releases/download/v${version}/${repo}_${version}_${platform}.zip";

in
stdenv.mkDerivation {
  inherit name version;
  src = fetchurl { inherit url sha256; };

  # Our source is right where the unzip happens, not in a "src/" directory (default)
  sourceRoot = ".";

  nativeBuildInputs = [ unzip ];
  installPhase = ''
    mkdir -p $out/bin
    mv ${name} $out/bin
  '';
}
