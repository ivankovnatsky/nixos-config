{

  local.services.syncthing-cleaner = {
    enable = true;
    intervalMinutes = 15;
    waitForPath = "/Volumes/Storage";
    paths = [
      "/Volumes/Storage/Data/Sources"
    ];
  };
}
