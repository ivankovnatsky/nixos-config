{
  config,
  pkgs,
  ...
}:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = config.flags.enableFishShell;

    # https://starship.rs/config/
    settings = {
      command_timeout = 1000;

      palette = if config.flags.darkMode then "dark" else "light";
      palettes =
        if config.flags.darkMode then
          {
            dark = { };
          }
        else
          {
            light = {
              "yellow" = "green";
            };
          };

      time = {
        disabled = false;
        time_format = "%h %d %R";
      };
      add_newline = false;
      aws.format = "on [$symbol$profile]($style) ";
      gcloud.disabled = true;
      git_status.disabled = true;
      git_branch.disabled = true;
      custom.jj = {
        when = "${pkgs.jj-starship}/bin/jj-starship detect";
        shell = [ "${pkgs.jj-starship}/bin/jj-starship" ];
        format = "$output ";
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
    };
  };
}
