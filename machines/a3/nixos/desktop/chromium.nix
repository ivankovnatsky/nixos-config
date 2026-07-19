{
  programs.chromium = {
    enable = true;

    extraOpts = {
      "BrowserSignin" = 0;
      "HardwareAccelerationModeEnabled" = true;

      "DefaultNotificationsSetting" = 2;
      # 1 = Allow sites to show desktop notifications
      # 2 = Do not allow any site to show desktop notifications
      # 3 = Ask every time a site wants to show desktop notifications

      "PasswordManagerEnabled" = false;
      "RestoreOnStartup" = 1; # 5 = Open New Tab Page 1 = Restore the last session 4 = Open a list of URLs
      "SearchSuggestEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [ "en-US" ];
      "SyncDisabled" = true;
      "TranslateEnabled" = true;
    };
  };
}
