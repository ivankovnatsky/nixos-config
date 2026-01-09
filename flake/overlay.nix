{ inputs }:
final: prev:
let
  # 1. Automatic overlays from overlays/ directory
  overlayDirs = builtins.readDir ../overlays;
  overlayList = builtins.mapAttrs (name: type: { inherit name type; }) overlayDirs;

  # Special arguments for specific overlays (like nixpkgs all-packages.nix)
  overlayArgs = {
    mangohud = {
      libXNVCtrl = prev.linuxPackages.nvidia_x11.settings.libXNVCtrl;
      mangohud32 = prev.pkgsi686Linux.mangohud;
    };
  };

  autoOverlays = builtins.foldl' (
    acc: dir:
    acc
    // {
      ${dir.name} = prev.callPackage (../overlays + "/${dir.name}") (overlayArgs.${dir.name} or { });
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
  system = final.stdenv.hostPlatform.system;
  masterOverlays = {
    nixpkgs-darwin-master = import inputs.nixpkgs-darwin-master {
      inherit system;
      inherit (final) config;
    };
    nixpkgs-darwin-master-beszel = import inputs.nixpkgs-darwin-master-beszel {
      inherit system;
      inherit (final) config;
    };
    nixpkgs-darwin-old-release = import inputs.nixpkgs-darwin-old-release {
      inherit system;
      inherit (final) config;
    };
    nixpkgs-nixos-master = import inputs.nixpkgs-nixos-master {
      inherit system;
      inherit (final) config;
    };
    nixpkgs-nixos-unstable = import inputs.nixpkgs-nixos-unstable {
      inherit system;
      inherit (final) config;
    };
  };

  # 4. Direct packages from other flakes
  flakeOverlays = {
    inherit (inputs.username.packages.${system}) username;
    inherit (inputs.podservice.packages.${system}) podservice;
    inherit (inputs.textcast.packages.${system}) textcast;

    pyenv-nix-install = inputs.pyenv-nix-install.packages.${system}.default;
  };

  # 5. Custom functions
  customFunctions = {
    # Element Web configured for Matrix homeserver
    # Args:
    #   domain: external domain (pass from runtime sops secret or string literal)
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
