{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, makeWrapper
, dbus
, libpulseaudio
, notmuch
, openssl
, ethtool
}:

rustPlatform.buildRustPackage rec {
  pname = "i3status-rust";
  version = "3200117999d7a9a82f33a03593a436cb89f83a7d";

  src = fetchFromGitHub {
    owner = "greshake";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-ZEL44Wp7xfr9dttpEgaIhV6YYPj2etalR/XcPrdxQtY=";
  };

  cargoSha256 = "sha256-xcew5yck13xNLv3J++5kQAefgM+0nDuFb3CSPV7Ucv0=";

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs = [ dbus libpulseaudio notmuch openssl ];

  cargoBuildFlags =
    [ "--features=notmuch" "--features=maildir" "--features=pulseaudio" ];

  prePatch = ''
    substituteInPlace src/util.rs \
      --replace "/usr/share/i3status-rust" "$out/share"
  '';

  postInstall = ''
    mkdir -p $out/share
    cp -R files/* $out/share
  '';

  postFixup = ''
    wrapProgram $out/bin/i3status-rs --prefix PATH : "${ethtool}/bin"
  '';

  # Currently no tests are implemented, so we avoid building the package twice
  doCheck = false;

  meta = with lib; {
    description =
      "Very resource-friendly and feature-rich replacement for i3status";
    homepage = "https://github.com/greshake/i3status-rust";
    license = licenses.gpl3;
    maintainers = with maintainers; [ backuitist globin ma27 ];
    platforms = platforms.linux;
  };
}
