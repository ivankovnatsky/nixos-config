{ config, ... }:

let
  jjCommand = builtins.readFile ./jj.template;
  jjstateCommand = builtins.readFile ./jjstate.template;
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = config.flags.enableFishShell;

    # https://starship.rs/config/
    settings = {
      command_timeout = 1000;

      time = {
        disabled = false;
        time_format = "%h %d %R";
      };
      add_newline = false;
      aws.format = "on [$symbol$profile]($style) ";
      gcloud.disabled = true;
      git_status.disabled = false;
      git_branch = {
        truncation_length = 30;
        truncation_symbol = "";
      };
      directory = {
        truncation_length = 1;
      };
      hostname.ssh_only = true;
      username.show_always = false;
      kubernetes = {
        disabled = false;
        contexts = [
          {
            context_pattern = ''arn.*\/(?P<cluster>[\w\/-]+)'';
            context_alias = "$cluster";
          }
        ];
      };
      rust.disabled = true;
      nodejs.disabled = true;
      package.disabled = true;

      custom.jj = {
        command = jjCommand;
        detect_folders = [ ".jj" ];
        symbol = "jj";
      };

      custom.jjstate = {
        command = jjstateCommand;
        detect_folders = [ ".jj" ];
      };
    };
  };
}
