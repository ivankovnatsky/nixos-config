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
  version = "1310907c98d160f8c23d3bd6091b68d91fa8a114";

  src = fetchFromGitHub {
    owner = "greshake";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-MGgVIAp1X3wBgfPCuvcsDR0VG8YcvHap5aktOW5oTa8=";
  };

  cargoSha256 = "sha256-hnaVv378YriHS2THUwAh1nUNJ0ijna28N/ktQWkEcsI=";

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
