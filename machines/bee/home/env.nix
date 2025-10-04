{ config, ... }:
{
  home.sessionVariables = {
    TR_AUTH = "${config.secrets.transmission.username}:${config.secrets.transmission.password}";
  };
}
