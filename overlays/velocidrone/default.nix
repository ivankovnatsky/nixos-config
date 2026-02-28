{
  lib,
  buildFHSEnv,
  requireFile,
  unzip,
  stdenv,
  copyDesktopItems,
  makeDesktopItem,
  zlib,
  xorg,
  fontconfig,
  freetype,
  glib,
  libGL,
  libpulseaudio,
  alsa-lib,
  vulkan-loader,
  systemd,
  dbus,
  sqlite,
}:

let
  version = "unstable";

  src = requireFile {
    name = "production-launcher-debian.zip";
    url = "https://www.velocidrone.com/download/launcher?id=debian&export=download";
    hash = "sha256-pVgQxuPkte5Apx05MuVGdh0MYaJ4Wxx+EhsUe79aiJU=";
  };

  launcher = stdenv.mkDerivation {
    pname = "velocidrone-launcher";
    inherit version src;

    nativeBuildInputs = [ unzip ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/share/velocidrone
      cp Launcher launcher.dat $out/share/velocidrone/
      chmod +x $out/share/velocidrone/Launcher
    '';
  };
  desktopItem = makeDesktopItem {
    name = "velocidrone";
    desktopName = "VelociDrone";
    comment = "FPV drone racing simulator";
    exec = "velocidrone";
    icon = "velocidrone";
    categories = [ "Game" "Simulation" ];
  };
in
buildFHSEnv {
  pname = "velocidrone";
  inherit version;

  targetPkgs = _: [
    zlib
    xorg.libxcb
    xorg.libX11
    xorg.libXi
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXrender
    xorg.xkeyboardconfig
    fontconfig
    freetype
    glib
    libGL
    libpulseaudio
    alsa-lib
    vulkan-loader
    systemd
    dbus
    sqlite
    stdenv.cc.cc.lib
  ];

  runScript = lib.getExe (stdenv.mkDerivation {
    name = "velocidrone-wrapper";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/velocidrone-wrapper <<'SCRIPT'
      #!/bin/sh
      dir="$HOME/.velocidrone"
      mkdir -p "$dir"
      cp "${launcher}/share/velocidrone/Launcher" "$dir/Launcher"
      cp "${launcher}/share/velocidrone/launcher.dat" "$dir/launcher.dat"
      chmod u+rwx "$dir/Launcher"
      chmod u+rw "$dir/launcher.dat"
      cd "$dir"
      exec ./Launcher "$@"
      SCRIPT
      chmod +x $out/bin/velocidrone-wrapper
    '';
    meta.mainProgram = "velocidrone-wrapper";
  });

  extraInstallCommands = ''
    install -Dm444 ${desktopItem}/share/applications/velocidrone.desktop \
      $out/share/applications/velocidrone.desktop
    install -Dm444 ${./velocidrone.png} \
      $out/share/icons/hicolor/128x128/apps/velocidrone.png
  '';

  meta = {
    description = "FPV drone racing simulator";
    homepage = "https://www.velocidrone.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
