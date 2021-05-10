{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, dbus
, libpulseaudio, notmuch, openssl, ethtool }:

rustPlatform.buildRustPackage rec {
  pname = "i3status-rust";
  version = "6bc6c141f37ac349512a0586987232977ade010e";

  src = fetchFromGitHub {
    owner = "GladOSkar";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-i5nu56smivvu4fkSu6OnfOeScy1XdLvhxsIgvc4KT04=";
  };

  cargoSha256 = "sha256-wh8LzfHobEDJnnf/SKF86GWvqlmnnp0mayA8BiuE1SQ=";

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs = [ dbus libpulseaudio notmuch openssl ];

  cargoBuildFlags = [ "--features=notmuch" "--features=maildir" ];

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
