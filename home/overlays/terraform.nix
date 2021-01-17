{ ... }:

# FIXME: move this to pkgs
let
  terraformOverlay = final: prev: {
    terraformCustom = final.terraform_0_14.withPlugins
      (p: [ p.aws p.helm p.kubernetes p.local p.null p.random p.template ]);

    terraform_0_14 = prev.terraform_0_14.overrideAttrs (old: rec {
      name = "terraform-${version}";
      version = "0.14.4";
      src = prev.fetchFromGitHub {
        owner = "hashicorp";
        repo = "terraform";
        rev = "v${version}";
        sha256 = "0kjbx1gshp1lvhnjfigfzza0sbl3m6d9qb3in7q5vc6kdkiplb66";
      };
    });

  };

in import <nixpkgs> { overlays = [ terraformOverlay ]; }
