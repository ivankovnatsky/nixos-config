{
  imports = [
    ./autorandr.nix
    ./i3.nix
    ./xserver-hidpi.nix
    ./xserver.nix
  ];

  services = {
    xserver = {
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };
  };
}
