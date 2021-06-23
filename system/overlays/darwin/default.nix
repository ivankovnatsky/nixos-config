self: super: {
  terraform = self.callPackage ../hashicorp-generic.nix {
    name = "terraform";
    version = "0.14.4";
    sha256 = "sha256-lI1FULfND5FSdBxKXk/oAWexy7dRP5Of/vHVD5TE+ww=";
    system = "x86_64-darwin";
  };
}
