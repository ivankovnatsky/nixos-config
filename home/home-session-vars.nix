{ config, ... }:
{
  sops.templates."session-secrets.sh".content = ''
    export OPENAI_API_KEY="${config.sops.placeholder.openai-api-key}"
    export ANTHROPIC_API_KEY="${config.sops.placeholder.anthropic-api-key}"
    export BW_SESSION="${config.sops.placeholder.bitwarden-session}"
  '';

  home.sessionVariables = {
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
  };

  home.sessionVariablesExtra = ''
    if [ -f ${config.sops.templates."session-secrets.sh".path} ]; then
      source ${config.sops.templates."session-secrets.sh".path}
    fi
  '';
}
