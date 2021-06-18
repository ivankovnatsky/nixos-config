self: super: {
  inherit (super.callPackages ../../system/overlays/openvpn.nix { })
    openvpn;

  i3status-rust = super.callPackage ../../system/overlays/i3status-rust.nix { };

  terraform = self.callPackage ../../system/overlays/hashicorp-generic.nix {
    name = "terraform";
    version = "0.14.4";
    sha256 = "1dalg9vw72vbmpfh7599gd3hppp6rkkvq4na5r2b75knni7iybq4";
    system = "x86_64-linux";
  };
}
