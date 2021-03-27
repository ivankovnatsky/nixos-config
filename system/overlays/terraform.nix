{ stdenv, lib, fetchurl, unzip }:

stdenv.mkDerivation rec {
  name = "terraform-${version}";
  version = "0.14.4";

  src = fetchurl {
    url =
      "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip";
    sha256 = "1dalg9vw72vbmpfh7599gd3hppp6rkkvq4na5r2b75knni7iybq4";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    install -m755 -D terraform $out/bin/terraform
  '';

  meta = with lib; {
    homepage = "https://terraform.io";
    description =
      "Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently.";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ivankovnatsky ];
  };
}
