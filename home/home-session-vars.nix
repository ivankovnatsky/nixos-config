{ config, ... }:
{
  home.sessionVariables = {
    OLLAMA_BASE_URL = "http://${config.inventory.a3Ip}:11434/v1";
    EDITOR = config.flags.editor;
    VISUAL = config.flags.editor;
    LESS = "-R";
  };
}
