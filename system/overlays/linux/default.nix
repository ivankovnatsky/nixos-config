self: super: {
  inherit (super.callPackages ../openvpn.nix { })
    openvpn;
}
