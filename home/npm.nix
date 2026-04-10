{ config, ... }:
{
  home.file = {
    ".npmrc".text = ''
      prefix=${config.flags.homeWorkPath}/.npm
      cache=${config.flags.homeWorkPath}/.npm-cache
    '';
  };
}
