{ config, ... }:
let
  notesPath =
    if config.flags.notesPath != "" then
      config.flags.notesPath
    else
      "${config.home.homeDirectory}/Notes";
in
{
  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
    MTASKS_ROOT = "${notesPath}/Tasks/Todo";
  };
}
