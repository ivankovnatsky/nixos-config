self: super: {
  terraform = super.callPackage ./terraform.nix { };
  i3status-rust = super.callPackage ./i3status-rust.nix { };
}
