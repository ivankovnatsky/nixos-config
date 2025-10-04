{ pkgs, ... }:

{
  # Using home-manager's chromium module for extensions and command-line args
  # This will install chromium and create a wrapper with extensions
  # Enterprise policies are configured via nixos/chromium.nix if imported
  # See: https://github.com/nix-community/home-manager/blob/master/modules/programs/chromium.nix
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    extensions = [
      { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark-reader
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # privacy-badger
      { id = "lckanjgmijmafbedllaakclkaicjfmnk"; } # clearurls
      { id = "ldpochfccmkkmhdbclfhpagapcfdljkj"; } # decentraleyes
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # https everywhere
      { id = "bkdgflcldnnnapblkhphbgpggdiikppg"; } # ddg
    ];

    commandLineArgs = [
      # Hardware acceleration
      "--enable-features=VaapiVideoDecoder"
      "--use-gl=desktop"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
    ];
  };
}
