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
      # Source config first
      source ${pkgs.fish-ai}/share/fish/vendor_conf.d/fish_ai.fish
      
      # Add paths after config
      set -a fish_function_path ${pkgs.fish-ai}/share/fish/vendor_functions.d
      set -a fish_complete_path ${pkgs.fish-ai}/share/fish/vendor_completions.d
      
      # Ensure Python module is in path
      set -x PYTHONPATH ${pkgs.fish-ai}/share/fish/vendor_functions.d:${pkgs.fish-ai}/lib/${pkgs.python3.sitePackages} $PYTHONPATH
    '';
  };

  home.file.".config/fish-ai.ini".text = ''
    [fish-ai]
    configuration = anthropic
    debug = True
    log = ~/.fish-ai/log.txt

    [anthropic]
    provider = anthropic
    api_key = ${config.secrets.anthropicApiKey}
  '';
}
