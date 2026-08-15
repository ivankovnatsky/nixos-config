{
  config,
  pkgs,
  ...
}:

let
  wolA3Script = pkgs.writeShellScript "wol-a3-guard" ''
    set -euo pipefail

    # Active daytime hours: 08:00 to 22:00
    HOUR=$(date +%H)
    HOUR=$((10#$HOUR))

    if [ "$HOUR" -lt 8 ] || [ "$HOUR" -ge 22 ]; then
      exit 0
    fi

    # Ensure local network/gateway is reachable before checking
    if ! /sbin/ping -c 1 -W 2 192.168.50.1 >/dev/null 2>&1; then
      exit 0
    fi

    # Check if a3 is responding to ping; if offline, wake it up
    if ! /sbin/ping -c 1 -W 2 "${config.inventory.a3Ip}" >/dev/null 2>&1; then
      echo "a3 (${config.inventory.a3Ip}) is offline during active hours. Sending Wake-on-LAN..."
      exec ${pkgs.homelab}/bin/homelab wol a3 --no-wait
    fi
  '';
in
{
  # https://github.com/nix-darwin/nix-darwin/blob/master/modules/power/sleep.nix
  # To prevent sleep, place "never".
  power.sleep = {
    computer = "never"; # default: 1
    display = 10; # default: 10
    harddisk = "never"; # default: 10
  };

  local.services.pmset = {
    enable = true;
    autoRestartOnPowerConnect = true;

    # To verify the current power management schedule state:
    # ```console
    # sudo pmset -g sched
    # ```
    # pmset repeat shutdown does not work forcefully - apps can block it via
    # power assertions (e.g., screensharingd, sharingd)
    # schedules = {
    #   ShutDown = {
    #     enable = true;
    #     time = "22:30:00";
    #     action = "shutdown";
    #   };
    # };
  };

  local.launchd.services.wol-a3 = {
    enable = true;
    command = "${wolA3Script}";
    runAtLoad = true;
    keepAlive = false;
    extraServiceConfig.StartInterval = 300;
  };
}
