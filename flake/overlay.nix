{ inputs }:
final: prev:
let
  # 1. Automatic overlays from overlays/ directory
  overlayDirs = builtins.readDir ../overlays;
  overlayList = builtins.mapAttrs (name: type: { inherit name type; }) overlayDirs;
  autoOverlays = builtins.foldl'
    (acc: dir: acc // {
      ${dir.name} = prev.callPackage (../overlays + "/${dir.name}") { };
    })
    { }
    (builtins.filter (dir: dir.type == "directory") (builtins.attrValues overlayList));

  # 2. Nixpkgs-master packages
  masterOverlays = {
    nixpkgs-master = import inputs.nixpkgs-master {
      inherit (final) system config;
    };
  };

  # 3. Direct packages from other flakes
  flakeOverlays = {
    username = inputs.username.packages.${final.system}.username;
  };
in
autoOverlays // masterOverlays // flakeOverlays 
