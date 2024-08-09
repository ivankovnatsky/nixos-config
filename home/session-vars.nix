{ config, ... }:
{
  home.sessionVariables = {
    AWS_VAULT_BACKEND = "pass";
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
    # https://github.com/kovidgoyal/kitty/issues/879
    TERM = "xterm-256color";
    # This is needed for aiac
    OPENAI_API_KEY = "${config.secrets.openaiApikey}";
  };
}
