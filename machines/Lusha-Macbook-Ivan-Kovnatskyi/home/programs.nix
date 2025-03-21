{ pkgs, ... }:
{
  programs = {
    # TODO:
    # 1. Make tf file comments italic
    home-manager.enable = true;
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/gh.nix#L115
    gh.extensions = with pkgs; [
      gh-token
      gh-copilot
    ];
  };
}
