let
  terraformOverlay = final: prev: {
    terraformFull = final.terraform_0_12.withPlugins (p: [ p.aws p.null ]);

    terraform_0_12 = prev.terraform_0_12.overrideAttrs (old: rec {
      name = "terraform-${version}";
      version = "0.12.28";
      src = prev.fetchFromGitHub {
        owner = "hashicorp";
        repo = "terraform";
        rev = "v${version}";
        sha256 = "05ymr6vc0sqh1sia0qawhz0mag8jdrq157mbj9bkdpsnlyv209p3";
      };
    });

    terraform-providers = prev.terraform-providers // {
      aws = prev.terraform-providers.aws.overrideAttrs (old: rec {
        name = "${old.repo}-${version}";
        version = "3.20.0";
        src = prev.fetchFromGitHub {
          owner = "hashicorp";
          repo = "terraform-provider-aws";
          rev = "v${version}";
          sha256 = "18zccjkdxzcprhpv3cn3b9fbp0h81pkj0dsygfz2islclljc3x17";
        };
        postBuild = "mv go/bin/${old.repo}{,_v${version}}";
      });
    };
  };
in import <nixpkgs> { overlays = [ terraformOverlay ]; }
