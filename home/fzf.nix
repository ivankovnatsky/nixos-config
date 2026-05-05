{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ripgrep
    fd
  ];

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f --hidden --no-ignore --follow --exclude .git";
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = config.flags.enableFishShell;
  };
}
