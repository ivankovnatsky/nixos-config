{ config, ... }:
{
  sops.templates."session-secrets.sh".content = ''
    export OPENAI_API_KEY="${config.sops.placeholder.openai-api-key}"
    export ABS_API_KEY="${config.sops.placeholder.audiobookshelf-api-token}"
    export ABS_URL="${config.sops.placeholder.audiobookshelf-url}"
    export GOOGLE_CLOUD_PROJECT="${config.sops.placeholder.google-cloud-project}"
    export ANTHROPIC_API_KEY="${config.sops.placeholder.anthropic-api-key}"
    export BW_SESSION="${config.sops.placeholder.bitwarden-session}"
  '';

  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
  };

  home.sessionVariablesExtra = ''
    source ${config.sops.templates."session-secrets.sh".path}
  '';
}
