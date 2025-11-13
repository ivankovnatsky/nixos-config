{ config
, pkgs
, ...
}:

{
  local.launchd.services.bin = {
    enable = true;
    command = ''
      ${pkgs.bin}/bin/bin \
        ${config.flags.miniIp}:8820 \
        --buffer-size 2000 \
        --max-paste-size 65536
    '';
  };
}
