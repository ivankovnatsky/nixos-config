{
  config,
  pkgs,
  username,
  ...
}:

let
  port = "8086";
  dataDir = "${config.flags.externalStoragePath}/.perlite";
  routerScript = ../../../../templates/perlite-router.php;
  homeDir = config.users.users.${username}.home;
  vaultPath = "${homeDir}/Library/Mobile Documents/iCloud~md~obsidian/Documents/Notes";
in
{
  local.launchd.services.perlite = {
    enable = true;
    type = "user-agent";
    waitForPath = config.flags.externalStoragePath;
    inherit dataDir;
    extraDirs = [
      dataDir
      "${dataDir}/tmp"
    ];
    preStart = ''
      export PATH="${pkgs.coreutils}/bin:$PATH"

      rm -rf ${dataDir}/app
      cp -r ${pkgs.perlite}/share/perlite ${dataDir}/app

      # Remove default settings.php (use env vars instead)
      rm -f ${dataDir}/app/settings.php

      # Copy router script for PHP built-in server
      cp ${routerScript} ${dataDir}/app/router.php

      # Symlink Obsidian vault into perlite directory
      ln -sfn "${vaultPath}" ${dataDir}/app/Notes
    '';
    environment = {
      NOTES_PATH = "Notes";
      SITE_TITLE = "Notes";
      SITE_NAME = "Notes";
      HIDE_FOLDERS = ".obsidian,.trash,trash";
      LINE_BREAKS = "true";
      SHOW_TOC = "true";
      SHOW_LOCAL_GRAPH = "true";
      NICE_LINKS = "true";
      HTML_SAFE_MODE = "true";
      FONT_SIZE = "15";
      HOME_FILE = "README";
      TEMP_PATH = "${dataDir}/tmp";
    };
    command = ''
      ${pkgs.php}/bin/php -S ${config.flags.machineBindAddress}:${port} -t ${dataDir}/app ${dataDir}/app/router.php
    '';
  };
}
