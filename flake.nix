{
  description = "NixOS configuration";

  inputs = {
    # This is used to pin packages from master channel.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # Pinned master commit for nix develop (2025-10-23)
    nixpkgs-master-pinned.url = "github:nixos/nixpkgs/3f173303fa32419a05ef1c0138045b03987adc05";

    # Unstable NixOS packages (for bee machine - binary cache available)
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable NixOS release
    nixpkgs-nixos-release.url = "github:nixos/nixpkgs/nixos-25.05";

    # Stable Darwin release
    nixpkgs-darwin-release.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";

    # Unstable Darwin packages
    nixpkgs-darwin-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin-darwin-unstable = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    nix-darwin-darwin-release = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin-release";
    };

    home-manager-darwin-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    home-manager-darwin-release = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin-release";
    };

    home-manager-nixos-release = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-nixos-release";
    };

    home-manager-nixos-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
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
    pomdtr-homebrew-tap = {
      url = "github:pomdtr/homebrew-tap";
      flake = false;
    };
    ivankovnatsky-homebrew-tap = {
      url = "github:ivankovnatsky/homebrew-tap";
      flake = false;
    };

    nur.url = "github:nix-community/NUR";

    # https://discourse.nixos.org/t/error-atopile-cannot-be-found-in-pkgs/70461
    nixvim-darwin-unstable = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    nixvim-darwin-release = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin-release";
    };

    nixvim-nixos-unstable = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    nixvim-nixos-release = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs-nixos-release";
    };

    flake-utils.url = "github:numtide/flake-utils";
    username = {
      url = "github:ivankovnatsky/username";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };

    backup-home = {
      url = "github:ivankovnatsky/backup-home-go";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };

    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    pyenv-nix-install.url = "github:sirno/pyenv-nix-install";

    # KDE Plasma configuration manager
    plasma-manager-nixos-release = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs-nixos-release";
      inputs.home-manager.follows = "home-manager-nixos-release";
    };

    plasma-manager-nixos-unstable = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
      inputs.home-manager.follows = "home-manager-nixos-unstable";
    };

    # Secrets management with SOPS
    sops-nix-darwin-release = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin-release";
    };

    sops-nix-darwin-unstable = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin-unstable";
    };

    sops-nix-nixos-release = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-nixos-release";
    };

    sops-nix-nixos-unstable = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    # Jovian-NixOS for Steam Deck
    jovian-nixos-unstable = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };

    # Pod Service - YouTube to Podcast Feed Service
    podservice.url = "github:ivankovnatsky/podservice";

    # Textcast - Text to Audio Service
    textcast.url = "github:ivankovnatsky/textcast";
  };

  outputs = { self, ... }@inputs: import ./flake { inherit inputs; };
}
