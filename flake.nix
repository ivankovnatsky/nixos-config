{
  description = "NixOS configuration";

  inputs = {
    # Naming convention for the inputs is:
    # $repo_name-$platform-$repo_branch

    # This is used to pin packages from master channel (NixOS).
    nixpkgs-nixos-master = {
      url = "github:nixos/nixpkgs/master";
    };

    nixpkgs-nixos-master-edge = {
      url = "github:nixos/nixpkgs/master";
    };

    # This is used to pin packages from master channel (Darwin).
    nixpkgs-darwin-master = {
      url = "github:nixos/nixpkgs/master";
    };

    nixpkgs-darwin-master-opencode = {
      url = "github:nixos/nixpkgs/master";
    };

    nixpkgs-darwin-master-gwq = {
      url = "github:nixos/nixpkgs/master";
    };

    # Pinned master commit for nix develop (2025-10-23)
    nixpkgs-master-pinned = {
      url = "github:nixos/nixpkgs/3f173303fa32419a05ef1c0138045b03987adc05";
    };

    # Unstable NixOS packages (binary cache available)
    nixpkgs-nixos-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    # Unstable Darwin packages
    nixpkgs-darwin-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    nix-darwin-darwin-unstable = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    home-manager-darwin-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    home-manager-nixos-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    # https://github.com/zhaofengli/nix-homebrew
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

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

    pomdtr-homebrew-tap = {
      url = "github:pomdtr/homebrew-tap";
      flake = false;
    };

    keith-homebrew-tap = {
      url = "github:keith/homebrew-formulae";
      flake = false;
    };

    antoniorodr-homebrew-tap = {
      url = "github:antoniorodr/homebrew-memo";
      flake = false;
    };

    xwmx-homebrew-tap = {
      url = "github:xwmx/homebrew-taps";
      flake = false;
    };

    nur-nixos-unstable = {
      url = "github:nix-community/NUR/main";
    };

    # https://discourse.nixos.org/t/error-atopile-cannot-be-found-in-pkgs/70461
    nixvim-darwin-unstable = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    nixvim-nixos-unstable = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    username = {
      url = "github:ivankovnatsky/username";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };

    passgen = {
      url = "github:ivankovnatsky/passgen";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };

    pyenv-nix-install = {
      url = "github:sirno/pyenv-nix-install";
    };

    # KDE Plasma configuration manager
    plasma-manager-nixos-unstable = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
      inputs.home-manager.follows = "home-manager-nixos-unstable";
    };

    # Secrets management with SOPS
    sops-nix-darwin-unstable = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    sops-nix-nixos-unstable = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    nix-steipete-tools = {
      url = "github:openclaw/nix-steipete-tools";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    # tools - declarative configuration manager
    tools = {
      url = "github:ivankovnatsky/tools";
    };

    # cx - Coralogix CLI
    cx-cli = {
      url = "github:coralogix/cx-cli";
    };

    # zapp - CLI tool for flashing ZSA keyboards (Linux only)
    zapp = {
      url = "github:zsa/zapp";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };
  };

  outputs = inputs: import ./flake { inherit inputs; };
}
