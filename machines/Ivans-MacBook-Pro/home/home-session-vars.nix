{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = config.flags.editor;
    ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
  };
}
