{ inputs, ... }:

{
  # Base module used across all configurations
  systemModule =
    {
      hostname,
      # Optional additional nixPath entries
      extraNixPath ? { },
      # Optional custom nixpkgs input
      nixpkgsInput ? inputs.nixpkgs,
      # Optional custom nixpkgs-release input (for Darwin stable)
      nixpkgsReleaseInput ? (if inputs ? nixpkgs-release then inputs.nixpkgs-release else null),
      # Optional custom nixos-release input (for NixOS stable)
      nixosReleaseInput ? (if inputs ? nixos-release then inputs.nixos-release else null),
    }:
    [
      {
        imports = [ ../../machines/${hostname} ];
        nixpkgs.overlays = [ inputs.self.overlay ];
        nixpkgs.config.allowUnfree = true;
      }
      {
        # NixOS expects nixPath to be a list of strings in the format "name=value"
        nix.nixPath =
          [
            "nixpkgs=${nixpkgsInput}"
          ]
          # Add nixpkgs-release for Darwin stable
          ++ (if nixpkgsReleaseInput != null then [ "nixpkgs-release=${nixpkgsReleaseInput}" ] else [ ])
          # Add nixos-release for NixOS stable
          ++ (if nixosReleaseInput != null then [ "nixos-release=${nixosReleaseInput}" ] else [ ])
          ++ (
            if extraNixPath != { } then
              (builtins.map (name: "${name}=${extraNixPath.${name}}") (builtins.attrNames extraNixPath))
            else
              [ ]
          );

        # Make inputs available to modules
        _module.args = {
          flake-inputs = inputs;
        };
      }
    ];
}
