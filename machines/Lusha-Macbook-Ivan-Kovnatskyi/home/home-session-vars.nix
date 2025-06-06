{ config, ... }:
{
  home = {
    sessionVariables = {
      EDITOR = config.flags.editor;
      VISUAL = config.flags.editor;
      OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
      ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    };
  };
}
