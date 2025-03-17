{ pkgs, ... }:

{
  imports = [
    # TODO: Create similar rebuild tmux service as in NixOS
    ../../darwin/syncthing.nix
  ];

  # error: Determinate detected, aborting activation
  # Determinate uses its own daemon to manage the Nix installation that
  # conflicts with nix-darwin’s native Nix management.
  #
  # To turn off nix-darwin’s management of the Nix installation, set:
  #
  #     nix.enable = false;
  #
  # This will allow you to use nix-darwin with Determinate. Some nix-darwin
  # functionality that relies on managing the Nix installation, like the
  # `nix.*` options to adjust Nix settings or configure a Linux builder,
  # will be unavailable.
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    # To avoid installing Developer Tools
    gnumake
    tmux

    rclone
  ];

  services.openssh.enable = true;
}
