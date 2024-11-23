{ config, pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  configPath =
    if isDarwin then
      "Library/Application Support/transmission-daemon"
    else if isLinux then
      ".config/transmission"
    else
      throw "Unsupported platform";

  downloadPath = "${config.home.homeDirectory}/Downloads";

in
{
  home.packages = with pkgs; [
    transmission_3
  ];

  home.file."${configPath}/settings.json".text = ''
    {
      "alt-speed-down": 50,
      "alt-speed-enabled": false,
      "alt-speed-time-begin": 540,
      "alt-speed-time-day": 127,
      "alt-speed-time-enabled": false,
      "alt-speed-time-end": 1020,
      "alt-speed-up": 50,
      "bind-address-ipv4": "0.0.0.0",
      "bind-address-ipv6": "::",
      "blocklist-date": 0,
      "blocklist-enabled": false,
      "blocklist-updates-enabled": true,
      "blocklist-url": "http://www.example.com/blocklist",
      "cache-size-mb": 4,
      "compact-view": false,
      "details-window-height": 1027,
      "details-window-width": 1920,
      "dht-enabled": true,
      "download-dir": "${downloadPath}",
      "download-queue-enabled": true,
      "download-queue-size": 5,
      "encryption": 1,
      "filter-mode": "show-all",
      "filter-trackers": "",
      "idle-seeding-limit": 30,
      "idle-seeding-limit-enabled": false,
      "incomplete-dir": "${downloadPath}",
      "incomplete-dir-enabled": false,
      "inhibit-desktop-hibernation": false,
      "lpd-enabled": false,
      "main-window-height": 1027,
      "main-window-is-maximized": 0,
      "main-window-layout-order": "menu,toolbar,filter,list,statusbar",
      "main-window-width": 1920,
      "main-window-x": 0,
      "main-window-y": 25,
      "message-level": 2,
      "open-dialog-dir": "${downloadPath}",
      "peer-congestion-algorithm": "",
      "peer-id-ttl-hours": 6,
      "peer-limit-global": 200,
      "peer-limit-per-torrent": 50,
      "peer-port": 62564,
      "peer-port-random-high": 65535,
      "peer-port-random-low": 49152,
      "peer-port-random-on-start": true,
      "peer-socket-tos": "default",
      "pex-enabled": true,
      "port-forwarding-enabled": true,
      "preallocation": 1,
      "prefetch-enabled": true,
      "prompt-before-exit": true,
      "queue-stalled-enabled": true,
      "queue-stalled-minutes": 30,
      "ratio-limit": 2,
      "ratio-limit-enabled": false,
      "recent-download-dir-1": "${downloadPath}",
      "remote-session-enabled": true,
      "remote-session-host": "localhost",
      "remote-session-password": "",
      "remote-session-port": 9091,
      "remote-session-requres-authentication": false,
      "remote-session-username": "",
      "rename-partial-files": true,
      "rpc-authentication-required": false,
      "rpc-bind-address": "0.0.0.0",
      "rpc-enabled": true,
      "rpc-host-whitelist": "",
      "rpc-host-whitelist-enabled": true,
      "rpc-password": "{ad45cdcf042cddd59d241b21e4a87ab79fcb41caDkcPBJUv",
      "rpc-port": 9091,
      "rpc-url": "/transmission/",
      "rpc-username": "",
      "rpc-whitelist": "127.0.0.1,::1",
      "rpc-whitelist-enabled": true,
      "scrape-paused-torrents-enabled": true,
      "script-torrent-done-enabled": false,
      "script-torrent-done-filename": "",
      "seed-queue-enabled": false,
      "seed-queue-size": 10,
      "show-backup-trackers": false,
      "show-extra-peer-details": false,
      "show-filterbar": true,
      "show-notification-area-icon": false,
      "show-options-window": true,
      "show-statusbar": true,
      "show-toolbar": true,
      "show-tracker-scrapes": false,
      "sort-mode": "sort-by-name",
      "sort-reversed": false,
      "speed-limit-down": 100,
      "speed-limit-down-enabled": false,
      "speed-limit-up": 100,
      "speed-limit-up-enabled": false,
      "start-added-torrents": true,
      "start-minimized": false,
      "statusbar-stats": "total-ratio",
      "torrent-added-notification-enabled": true,
      "torrent-complete-notification-enabled": true,
      "torrent-complete-sound-command": "canberra-gtk-play -i complete-download -d 'transmission torrent downloaded'",
      "torrent-complete-sound-enabled": true,
      "trash-can-enabled": true,
      "trash-original-torrent-files": true,
      "umask": 18,
      "upload-slots-per-torrent": 14,
      "user-has-given-informed-consent": true,
      "utp-enabled": true,
      "watch-dir": "${downloadPath}",
      "watch-dir-enabled": true
    }
  '';
}
