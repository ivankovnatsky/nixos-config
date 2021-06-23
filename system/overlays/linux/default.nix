self: super: {
  inherit (super.callPackages ../openvpn.nix { })
    openvpn;

  i3status-rust = super.callPackage ../i3status-rust.nix { };

  terraform = self.callPackage ../hashicorp-generic.nix {
    name = "terraform";
    version = "0.14.4";
    sha256 = "1dalg9vw72vbmpfh7599gd3hppp6rkkvq4na5r2b75knni7iybq4";
    system = "x86_64-linux";
  };
}
