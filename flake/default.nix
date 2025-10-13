{ inputs, ... }:
let
  machines = import ./machines { inherit inputs; };

  # Development shell for working on this config
  forAllSystems = inputs.flake-utils.lib.eachDefaultSystem;
in
{
  inherit (machines) darwinConfigurations nixosConfigurations;
  overlay = import ./overlay.nix { inherit inputs; };
}
// forAllSystems (system:
  let
    pkgs = import inputs.nixpkgs-darwin-unstable { inherit system; };
  in
  {
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        # Version control
        git
        git-crypt
        gnupg

        # Development tools
        tmux
        gnumake
        neovim

        # Nix tools
        nixfmt-rfc-style
        nixpkgs-fmt
        nil # Nix LSP

        # Shell tools
        ripgrep
        fd
        jq
        fish
      ];
    };
  }
)
