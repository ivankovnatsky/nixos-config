{ lib
, buildFishPlugin
, fetchFromGitHub
}:

buildFishPlugin rec {
  pname = "fish-ai";
  version = "v1.0.0";

  src = fetchFromGitHub {
    owner = "Realiserad";
    repo = "fish-ai";
    rev = version;
    hash = lib.fakeHash;
  };

  postInstall = ''
    install -Dm644 functions/*.fish $out/share/fish/vendor_functions.d/
    install -Dm644 conf.d/*.fish $out/share/fish/vendor_conf.d/
  '';

  meta = with lib; {
    description = "AI assistant integration for the fish shell";
    homepage = "https://github.com/Realiserad/fish-ai";
    license = licenses.mit;
    maintainers = [ ];
  };
} 
