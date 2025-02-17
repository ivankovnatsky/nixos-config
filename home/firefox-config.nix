{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;

  configPath = if isDarwin then "Library/Application Support/Firefox" else ".mozilla/firefox";

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
    user_pref("app.update.url.details", "https://non-existent-site");
    user_pref("app.update.url.manual", "https://non-existent-site");
    user_pref("media.videocontrols.picture-in-picture.enabled", false);
    user_pref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);
    user_pref("media.videocontrols.picture-in-picture.video-toggle.has-used", false);
  '';

  defaultLinuxConfig = ''
    ${defaultConfig}
    user_pref("widget.wayland-dmabuf-vaapi.enabled", true);
    user_pref("gfx.webrender.all", true);
  '';

  userChromeConfig = ''
    #TabsToolbar {
      visibility: collapse;
    }

    #sidebar-header {
      display: none;
    }
  '';
in
{
  # To make sure this will work you have to create profile manually on macOS:
  #
  # ```
  # /Applications/Firefox.app/Contents/MacOS/firefox -P
  # ```
  home.file =
    if config.flags.purpose == "work" then
      {
        # Default
        "${configPath}/Profiles/Default/user.js" = if isDarwin then { text = defaultConfig; } else { };

        "${configPath}/Profiles/Default/chrome/userChrome.css" =
          if isDarwin then { text = userChromeConfig; } else { };

        # Personal
        "${configPath}/Profiles/Personal/user.js" = if isDarwin then { text = defaultConfig; } else { };

        "${configPath}/Profiles/Personal/chrome/userChrome.css" =
          if isDarwin then { text = userChromeConfig; } else { };
      }
    else
      {
        # Home
        "${configPath}/Profiles/Home/user.js" = if isDarwin then { text = defaultConfig; } else { };

        "${configPath}/Profiles/Home/chrome/userChrome.css" =
          if isDarwin then { text = userChromeConfig; } else { };
      };
}
