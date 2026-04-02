{ config, ... }:
{
  home.file = {
    ".npmrc".text = ''
      prefix=${config.local.tools.toolsPrefix}/.npm
    '';
  };
}
