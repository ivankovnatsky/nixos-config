{ stdenv
, lib
, dpkg
, openssl
, libnl
, zlib
, autoPatchelfHook
, buildFHSEnv
, ...
}:

let
  pname = "falcon-sensor";
  arch = "amd64";
  # You need to get the binary from #it guys
  # mkdir -p /opt/CrowdStrikeDistro/
  # mv /tmp/falcon*.deb /opt/CrowdStrikeDistro/
  src = /opt/CrowdStrikeDistro/falcon-sensor_6.47.0-14408_amd64.deb;
  falcon-sensor = stdenv.mkDerivation {
    inherit arch src;
    name = pname;

    buildInputs = [ dpkg zlib autoPatchelfHook ];

    sourceRoot = ".";

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      cp -r . $out
    '';

    meta = with lib; {
      description = "Crowdstrike Falcon Sensor";
      homepage = "https://www.crowdstrike.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  };
in

# https://gist.github.com/ravloony/2f5682fad481168dfb5778e911f47bee?permalink_comment_id=4612688#gistcomment-4612688
buildFHSEnv {
  name = "fs-bash";
  unsharePid = false;
  targetPkgs = pkgs: [ libnl openssl zlib ];

  extraInstallCommands = ''
    ln -s ${falcon-sensor}/* $out/
  '';

  runScript = "bash";
}
