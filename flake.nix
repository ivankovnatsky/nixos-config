{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from master channel.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/zhaofengli/nix-homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    nur.url = "github:nix-community/NUR";

    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
    username = {
      url = "github:ivankovnatsky/username";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    pyenv-nix-install.url = "github:sirno/pyenv-nix-install";
  };

  outputs = { self, ... }@inputs: {
    inherit (import ./flake/darwin.nix { inherit inputs; }) darwinConfigurations;
    overlay = import ./flake/overlay.nix { inherit inputs; };
  };
}
