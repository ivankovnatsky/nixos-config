{ config, ... }:
{
  home = {
    sessionVariables = {
      OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
      ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    };
  };
}
