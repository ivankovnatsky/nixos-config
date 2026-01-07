{ pkgs, ... }:

{
  local.launchd.services.prevent-kandji = {
    enable = true;
    type = "daemon";
    command = "${pkgs.pblock}/bin/pblock kandji";
    runAtLoad = true;
    keepAlive = false;
  };
}
