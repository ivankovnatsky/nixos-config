{ config, ... }:
{
  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
    OPENAI_API_KEY = "${config.secrets.openaiApiKey}";
    ABS_API_KEY = "${config.secrets.audiobookshelf.apiToken}";
    ABS_URL = "${config.secrets.audiobookshelf.url}";
    GOOGLE_CLOUD_PROJECT = "${config.secrets.googleCloudProject}";
    ANTHROPIC_API_KEY = "${config.secrets.anthropicApiKey}";
    BW_SESSION = "${config.secrets.bitwardenSession}";
  };
}
