{ inputs }:
final: prev:
let
  # 1. Automatic overlays from overlays/ directory
  overlayDirs = builtins.readDir ../overlays;
  overlayList = builtins.mapAttrs (name: type: { inherit name type; }) overlayDirs;

  # List of overlays that need buildFishPlugin
  fishPluginOverlays = [ "fish-ai" ];

  # Helper function to get appropriate arguments for each overlay
  getOverlayArgs =
    name:
    if builtins.elem name fishPluginOverlays then
      { buildFishPlugin = prev.fishPlugins.buildFishPlugin; }
    else
      { };

  autoOverlays = builtins.foldl' (
    acc: dir:
    acc
    // {
      ${dir.name} = prev.callPackage (../overlays + "/${dir.name}") (getOverlayArgs dir.name);
    }
  ) { } (builtins.filter (dir: dir.type == "directory") (builtins.attrValues overlayList));

  # 2. Nixpkgs-master and unstable packages
  masterOverlays = {
    nixpkgs-master = import inputs.nixpkgs-master {
      inherit (final) system config;
    };
    nixpkgs-unstable-nixos = import inputs.nixpkgs-unstable-nixos {
      inherit (final) system config;
    };
  };

  # 3. Direct packages from other flakes
  flakeOverlays = {
    inherit (inputs.username.packages.${final.system}) username;
    inherit (inputs.backup-home.packages.${final.system}) backup-home;

    pyenv-nix-install = inputs.pyenv-nix-install.packages.${final.system}.default;
  };

  # 4. Custom functions
  customFunctions = {
    # Element Web configured for Matrix homeserver
    mkElementWeb = externalDomain: prev.element-web.override {
      conf = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://matrix.${externalDomain}";
            server_name = "matrix.${externalDomain}";
          };
        };
        default_theme = "dark";
        show_labs_settings = true;
      };
    };
  };
in
autoOverlays // masterOverlays // flakeOverlays // customFunctions
