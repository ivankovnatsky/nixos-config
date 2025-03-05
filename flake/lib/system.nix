{ inputs, ... }:

{
  # Base module used across all configurations
  systemModule =
    {
      hostname,
      # Optional additional nixPath entries
      extraNixPath ? { },
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
            "nixpkgs=${inputs.nixpkgs}"
          ]
          ++ (if inputs ? nixos-release then [ "nixos-release=${inputs.nixos-release}" ] else [ ])
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
