self: super: {
  inherit (super.callPackages ../openvpn.nix { })
    openvpn;

  i3status-rust = super.callPackage ../i3status-rust.nix { };

  terraform = self.callPackage ../hashicorp-generic.nix {
    name = "terraform";
    version = "0.15.5";
    sha256 = "sha256-OxREmeCMJFqAOQJ+srhMBJXhGfV9eej7YFhku0iJen0=";
    system = "x86_64-linux";
  };
}
