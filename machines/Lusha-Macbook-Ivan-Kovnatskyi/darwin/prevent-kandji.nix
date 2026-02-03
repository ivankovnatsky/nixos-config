{ pkgs, ... }:

{
  local.launchd.services.prevent-kandji = {
    enable = false;
    type = "daemon";
    command = "${pkgs.pblock}/bin/pblock kandji";
    runAtLoad = true;
    keepAlive = false;
  };
}
