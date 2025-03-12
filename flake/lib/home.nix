{ inputs, ... }:
let
  # Common home configuration function
  makeHomeConfiguration =
    {
      hmModule,
      nixpkgsInput ? inputs.nixpkgs,
    }:
    {
      hostname,
      username,
      extraImports ? [ ],
    }:
    [
      hmModule
      (
        { config, system, ... }:
        {
          nix.nixPath.nixpkgs = "${nixpkgsInput}";

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = {
              imports = [
                ../../machines/${hostname}/home.nix
                {
                  programs.home-manager.enable = true;
                }
              ] ++ extraImports;
            };

            extraSpecialArgs = {
              inherit inputs system username;
              super = config;
            };

            sharedModules = [
              {
                # ```console
                # … while calling the 'derivationStrict' builtin
                #   at <nix/derivation-internal.nix>:34:12:
                #     33|
                #     34|   strict = derivationStrict drvAttrs;
                #       |            ^
                #     35|
                #
                # … while evaluating derivation 'darwin-system-25.05.4052178'
                #   whose name attribute is located at /nix/store/m4wcdchjxw2fdyzjp8i6irpc613pchkr-source/pkgs/stdenv/generic/make-derivation.nix:375:7
                #
                # … while evaluating attribute 'activationScript' of derivation 'darwin-system-25.05.4052178'
                #   at /nix/store/r7w65jwlv1m3sdw30cfzhadygb92krpi-source/modules/system/default.nix:97:7:
                #     96|
                #     97|       activationScript = cfg.activationScripts.script.text;
                #       |       ^
                #     98|       activationUserScript = cfg.activationScripts.userScript.text;
                #
                # … while evaluating the option `system.activationScripts.script.text':
                #
                # … while evaluating definitions from `/nix/store/r7w65jwlv1m3sdw30cfzhadygb92krpi-source/modules/system/activation-scripts.nix':
                #
                # … while evaluating the option `system.activationScripts.postActivation.text':
                #
                # … while evaluating definitions from `<unknown-file>':
                #
                # … while evaluating the option `home-manager.users."Ivan.Kovnatskyi".nix.package':
                #
                # … while evaluating definitions from `/nix/store/mldpn4s578783cshnqax2wzz8nnf1h7n-source/nixos/common.nix':
                #
                # … while evaluating the option `nix.package':
                #
                # (stack trace truncated; use '--show-trace' to show the full, detailed trace)
                #
                # error: nix.package: accessed when `nix.enable` is off; this is a bug in
                # nix-darwin or a third‐party module
                # waiting for changes
                # ```
                nix.enable = false;
              }
            ];
          };
        }
      )
    ];

  # Unstable modules
  darwinHomeManagerModule = makeHomeConfiguration {
    hmModule = inputs.home-manager.darwinModules.home-manager;
    nixpkgsInput = inputs.nixpkgs;
  };

  nixosHomeManagerModule = makeHomeConfiguration {
    hmModule = inputs.home-manager.nixosModules.home-manager;
    nixpkgsInput = inputs.nixpkgs;
  };

  # Stable modules
  stableDarwinHomeManagerModule = makeHomeConfiguration {
    hmModule = inputs.home-manager-release.darwinModules.home-manager;
    nixpkgsInput = inputs.nixpkgs-release;
  };

  stableNixosHomeManagerModule = makeHomeConfiguration {
    hmModule = inputs.home-manager-release.nixosModules.home-manager;
    nixpkgsInput = inputs.nixpkgs-release;
  };
in
{
  # For backward compatibility
  homeManagerModule = darwinHomeManagerModule;

  # Expose all modules
  inherit darwinHomeManagerModule nixosHomeManagerModule;
  inherit stableDarwinHomeManagerModule stableNixosHomeManagerModule;
}
