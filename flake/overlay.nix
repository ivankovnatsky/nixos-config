{ inputs }:
final: prev:
let
  # 1. Automatic overlays from overlays/ directory
  overlayDirs = builtins.readDir ../overlays;
  overlayList = builtins.mapAttrs (name: type: { inherit name type; }) overlayDirs;

  autoOverlays = builtins.foldl' (
    acc: dir:
    acc
    // {
      ${dir.name} = prev.callPackage (../overlays + "/${dir.name}") { };
    }
  ) { } (builtins.filter (dir: dir.type == "directory") (builtins.attrValues overlayList));

  # 2. Automatic packages from packages/ directory
  packageDirs = builtins.readDir ../packages;
  packageList = builtins.mapAttrs (name: type: { inherit name type; }) packageDirs;

  autoPackages = builtins.foldl' (
    acc: dir:
    acc
    // {
      ${dir.name} = prev.callPackage (../packages + "/${dir.name}") { };
    }
  ) { } (builtins.filter (dir: dir.type == "directory") (builtins.attrValues packageList));

  # 3. Nixpkgs-master and unstable packages
  masterOverlays = {
    nixpkgs-master = import inputs.nixpkgs-master {
      inherit (final) system config;
    };
    nixpkgs-nixos-unstable = import inputs.nixpkgs-nixos-unstable {
      inherit (final) system config;
    };
  };

  # 4. Direct packages from other flakes
  flakeOverlays = {
    inherit (inputs.username.packages.${final.system}) username;
    inherit (inputs.backup-home.packages.${final.system}) backup-home;

    pyenv-nix-install = inputs.pyenv-nix-install.packages.${final.system}.default;
  };

  # 5. Custom functions
  customFunctions = {
    # Element Web configured for Matrix homeserver
    # Args:
    #   domain: external domain (e.g., config.secrets.externalDomain)
    #   homeserverSubdomain: subdomain for homeserver (e.g., "matrix", "matrix-mini")
    mkElementWeb =
      domain: homeserverSubdomain:
      prev.element-web.override {
        conf = {
          default_server_config = {
            "m.homeserver" = {
              base_url = "https://${homeserverSubdomain}.${domain}";
              server_name = "${homeserverSubdomain}.${domain}";
            };
          };
          default_theme = "dark";
          show_labs_settings = true;
        };
      };
  };
in
autoOverlays // autoPackages // masterOverlays // flakeOverlays // customFunctions
