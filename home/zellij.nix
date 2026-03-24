{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # zesh
  ];

  # https://github.com/nix-community/home-manager/blob/master/modules/programs/zellij.nix
  # ```console
  # zellij setup --dump-config
  # ```
  programs.zellij = {
    enable = true;

    settings = {
      # pane_frames = false;
      # simplified_ui = true;

      # Copy to clipboard configuration
      copy_command = if pkgs.stdenv.hostPlatform.isDarwin then "pbcopy" else "wl-copy";
    };
  };
}
