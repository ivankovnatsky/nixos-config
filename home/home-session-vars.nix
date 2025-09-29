{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
    OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
    ABS_API_KEY = "${config.secrets.audioBookShelfApiKey}";
    ABS_URL = "${config.secrets.audioBookShelfUrl}";
    GOOGLE_CLOUD_PROJECT = "${config.secrets.googleCloudProject}";
    ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    BW_SESSION = "${config.secrets.bitwardenSession}";
  };
}
