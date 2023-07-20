{ stdenv
, lib
, dpkg
, openssl
, libnl
, zlib
, autoPatchelfHook
, buildFHSUserEnv
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

buildFHSUserEnv {
  name = "fs-bash";
  targetPkgs = pkgs: [ libnl openssl zlib ];

  extraInstallCommands = ''
    ln -s ${falcon-sensor}/* $out/
  '';

  runScript = "bash";
}
