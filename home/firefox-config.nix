{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  configPath = if isDarwin then "Library/Application Support/Firefox" else ".mozilla/firefox";

  userConfigPath = if isDarwin then "Profiles/0ychrwr5.default-release" else "default";

  defaultConfig = ''
    user_pref("browser.contentblocking.category", "strict");
    user_pref("browser.ctrlTab.recentlyUsedOrder", true);
    user_pref("browser.ctrlTab.sortByRecentlyUsed", true);
    user_pref("browser.download.dir", "/tmp");
    user_pref("browser.engagement.ctrlTab.has-used", true);
    user_pref("browser.fullscreen.autohide", false);
    user_pref("browser.safebrowsing.appRepURL", "");
    user_pref("browser.safebrowsing.malware.enabled", false);
    user_pref("browser.search.hiddenOneOffs", "Google,Yahoo,Bing,Amazon.com,Twitter");
    user_pref("browser.search.suggest.enabled", false);
    user_pref("browser.send_pings", false);
    user_pref("browser.startup.page", 3);
    user_pref("browser.toolbars.bookmarks.visibility", "never");
    user_pref("dom.security.https_only_mode", true);
    user_pref("extensions.pocket.enabled", false);
    user_pref("general.smoothScroll", true);
    user_pref("geo.enabled", false);
    user_pref("network.allow-experiments", false);
    user_pref("network.dns.disablePrefetch", true);
    user_pref("permissions.default.desktop-notification", 2);
    user_pref("privacy.donottrackheader.enabled", true);
    user_pref("privacy.donottrackheader.value", 1);
    user_pref("security.sandbox.content.level", 3);
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    user_pref("app.update.silent", true);
  '';
in
{
  home.file = {
    "${configPath}/profiles.ini" = {
      text =
        if isDarwin then ''
          [Profile1]
          Name=default
          IsRelative=1
          Path=Profiles/a2270yxa.default
          Default=1

          [Profile0]
          Name=default-release
          IsRelative=1
          Path=${userConfigPath}

          [General]
          StartWithLastProfile=1
          Version=2

          [Install2656FF1E876E9973]
          Default=${userConfigPath}
          Locked=1
        '' else ''
          [ General ]
          StartWithLastProfile=1

          [Profile0]
          Default=1
          IsRelative=1
          Name=default
          Path=default
        '';
    };

    "${configPath}/${userConfigPath}/user.js" = {
      text =
        if isDarwin then ''
          ${defaultConfig}
        '' else ''
          ${defaultConfig}
          user_pref("media.videocontrols.picture-in-picture.enabled", false);
          user_pref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);
          user_pref("media.videocontrols.picture-in-picture.video-toggle.has-used", false);
          user_pref("widget.wayland-dmabuf-vaapi.enabled", true);
          user_pref("gfx.webrender.all", true);
        '';
    };

    "${configPath}/${userConfigPath}/chrome/userChrome.css" = {
      text = ''
        #TabsToolbar {
          visibility: collapse;
        }
      '';
    };
  };
}
