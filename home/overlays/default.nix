self: super: { terraform-custom = super.callPackage ./terraform.nix { }; }
