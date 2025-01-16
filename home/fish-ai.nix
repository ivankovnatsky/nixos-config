{ config, pkgs, ... }:

{
  programs.fish = {
    plugins = [
      {
        name = "fish-ai";
        src = pkgs.fish-ai;
      }
    ];

    interactiveShellInit = ''
    '';
  };

  home.file.".config/fish-ai.ini".text = ''
    [fish-ai]
    configuration = anthropic

    # [self-hosted]
    # provider = self-hosted
    # server = https://<your server>:<port>/v1
    # model = <your model>
    # api_key = <your API key>
    #
    # [fish-ai]
    # configuration = local-llama
    #
    # [local-llama]
    # provider = self-hosted
    # model = llama3.3
    # server = http://localhost:11434/v1
    #
    # [fish-ai]
    # configuration = openai
    #
    # [openai]
    # provider = openai
    # model = gpt-4o
    # api_key = <your API key>
    # organization = <your organization>

    [anthropic]
    provider = anthropic
    api_key = ${config.secrets.anthropicApiKey}
  '';
} 
