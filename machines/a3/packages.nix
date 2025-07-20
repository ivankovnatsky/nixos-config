{ pkgs, ... }:

{
  # System packages for a3
  environment.systemPackages = with pkgs; [
    lsof  # List open files
  ];
}
