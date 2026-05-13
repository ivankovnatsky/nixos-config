{ inputs }:
final: prev:
let
  # 1. Automatic overlays from overlays/ directory
  overlayDirs = builtins.readDir ../overlays;
  overlayList = builtins.mapAttrs (name: type: { inherit name type; }) overlayDirs;

  # Special arguments for specific overlays (like nixpkgs all-packages.nix)
  overlayArgs = {
    mangohud = {
      inherit (prev.linuxPackages.nvidia_x11.settings) libXNVCtrl;
      mangohud32 = prev.pkgsi686Linux.mangohud;
    };
    gwq = {
      inherit (masterOverlays.nixpkgs-darwin-master-gwq) go_1_26;
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

  # Special arguments for specific packages (to break overlay self-reference cycles)
  packageArgs = {
    genpass = {
      inherit (prev) genpass;
    };
  };

  autoPackages =
    builtins.foldl'
      (
        acc: dir:
        acc
        // {
          ${dir.name} = prev.callPackage (../packages + "/${dir.name}") (packageArgs.${dir.name} or { });
        }
      )
      { }
      (
        builtins.filter (
          dir: dir.type == "directory" && builtins.pathExists (../packages + "/${dir.name}/default.nix")
        ) (builtins.attrValues packageList)
      );

  # 3. Nixpkgs-master and unstable packages
  inherit (final.stdenv.hostPlatform) system;
  # Filter out null values from config to avoid replaceStdenv = null breaking imports
  safeConfig = builtins.removeAttrs final.config [ "replaceStdenv" ];
  masterOverlays = {
    nixpkgs-darwin-master = import inputs.nixpkgs-darwin-master {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-darwin-master-opencode = import inputs.nixpkgs-darwin-master-opencode {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-darwin-master-ytdlp = import inputs.nixpkgs-darwin-master-ytdlp {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-darwin-master-gallery-dl = import inputs.nixpkgs-darwin-master-gallery-dl {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-darwin-master-gwq = import inputs.nixpkgs-darwin-master-gwq {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-darwin-old-release = import inputs.nixpkgs-darwin-old-release {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-nixos-master = import inputs.nixpkgs-nixos-master {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-nixos-master-ollama = import inputs.nixpkgs-nixos-master-ollama {
      inherit system;
      config = safeConfig;
    };
    nixpkgs-nixos-unstable = import inputs.nixpkgs-nixos-unstable {
      inherit system;
      config = safeConfig;
    };
  };

  # 4. Direct packages from other flakes
  flakeOverlays = {
    inherit (inputs.username.packages.${system}) username;

    rems = inputs.rems.packages.${system}.default;
    pyenv-nix-install = inputs.pyenv-nix-install.packages.${system}.default;
    cx-cli = inputs.cx-cli.packages.${system}.default;
  };

  # 5. In-place overrides of upstream nixpkgs derivations
  extraOverrides = {
    # kvazaar tests get killed by the macOS sandbox/OOM during ffmpeg pipe
    # tests on aarch64-darwin, breaking ffmpeg-full → pydub → markitdown.
    kvazaar = prev.kvazaar.overrideAttrs (_: {
      doCheck = false;
    });

    # jeepney 0.9 in nixpkgs has issues breaking pass-import → pass and
    # secretstorage chains on darwin:
    #   1. installCheckPhase calls dbus-run-session, which cannot start on
    #      darwin (DBUS_LAUNCHD_SESSION_BUS_SOCKET unset). Tracked upstream:
    #      NixOS/nixpkgs#493775.
    #   2. pythonImportsCheck imports jeepney.io.trio, which imports `outcome`
    #      and `trio` at module top-level, neither propagated. We don't use
    #      the trio backend, so drop it from pythonImportsCheck instead of
    #      propagating its deps into every jeepney consumer's closure.
    python313 = prev.python313.override {
      packageOverrides = _pyfinal: pyprev: {
        jeepney = pyprev.jeepney.overrideAttrs (old: {
          doInstallCheck = false;
          pythonImportsCheck = builtins.filter (m: m != "jeepney.io.trio") (old.pythonImportsCheck or [ ]);
        });
      };
    };
  };

in
autoOverlays // autoPackages // masterOverlays // flakeOverlays // extraOverrides
