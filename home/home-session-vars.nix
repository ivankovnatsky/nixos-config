{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
  };
}
