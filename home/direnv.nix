{
  # https://home-manager-options.extranix.com/?query=programs.direnv.&release=release-23.11
  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # see note on other shells below
    nix-direnv.enable = true;
  };
}
