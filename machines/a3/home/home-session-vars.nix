{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = config.flags.editor;
  };
}
