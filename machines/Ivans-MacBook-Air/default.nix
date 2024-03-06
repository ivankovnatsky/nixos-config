{ ... }:

{
  imports = [
    ../../system/darwin.nix
  ];

  homebrew = {
    casks = [
      # To use PC mouse with natural scrolling
      "mos"
      "coconutbattery"
    ];

    masApps = {
      "Bitwarden" = 1352778147;
      "NextDNS" = 1464122853;
    };
  };

  nixpkgs.overlays = [ ];
}
