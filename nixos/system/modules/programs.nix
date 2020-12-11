{ pkgs, ... }:

{
  programs = {

    ssh = {
      extraConfig = ''
        Host *
          IdentityFile ~/.ssh/id_ed25519
          IdentityFile ~/.ssh/id_ed25519_1
          IdentityFile ~/.ssh/id_ed25519_work
      '';
    };

    slock.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    chromium = {
      enable = true;

      homepageLocation = "";
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q=%s";

      extensions = [
        "ecabifbgmdmgdllomnfinbmaellmclnh" # reader-view
        "lckanjgmijmafbedllaakclkaicjfmnk" # clearurls
        "ldpochfccmkkmhdbclfhpagapcfdljkj" # decentraleyes
        "lcbjdhceifofjlpecfpeimnnphbcjgnc" # xbrowsersync
        "ecabifbgmdmgdllomnfinbmaellmclnh" # reader view
        "madlgmccpddkhohkdobabokeecnjonhl" # krypton
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
        "bkdgflcldnnnapblkhphbgpggdiikppg" # ddg
      ];

      # https://cloud.google.com/docs/chrome-enterprise/policies/
      extraOpts = {
        "BrowserSignin" = 0;
        "HardwareAccelerationModeEnabled" = true;
        "PasswordManagerEnabled" = false;
        "RestoreOnStartup" =
          1; # 5 = Open New Tab Page 1 = Restore the last session 4 = Open a list of URLs
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-US" ];
        "SyncDisabled" = true;
        "TranslateEnabled" = false;
      };
    };
  };
}
