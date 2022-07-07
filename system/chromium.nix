{
  programs = {
    chromium = {
      enable = true;

      homepageLocation = "";

      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      defaultSearchProviderSuggestURL = "https://duckduckgo.com/?q={searchTerms}";

      extensions = [
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1password-–-password-mana
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark-reader
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy-badger
        "lckanjgmijmafbedllaakclkaicjfmnk" # clearurls
        "ldpochfccmkkmhdbclfhpagapcfdljkj" # decentraleyes
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
        "bkdgflcldnnnapblkhphbgpggdiikppg" # ddg
      ];

      # https://cloud.google.com/docs/chrome-enterprise/policies/
      extraOpts = {
        "DefaultSearchProviderEnabled" = true;
        "DownloadDirectory" = "/tmp";
        "BrowserSignin" = 0;
        "HardwareAccelerationModeEnabled" = true;

        "DefaultNotificationsSetting" = 2;
        # 1 = Allow sites to show desktop notifications
        # 2 = Do not allow any site to show desktop notifications
        # 3 = Ask every time a site wants to show desktop notifications

        "PasswordManagerEnabled" = false;
        "RestoreOnStartup" = 1; # 5 = Open New Tab Page 1 = Restore the last session 4 = Open a list of URLs
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-US" ];
        "SyncDisabled" = true;
        "TranslateEnabled" = true;
      };
    };
  };
}
