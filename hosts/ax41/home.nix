{ pkgs, ... }:

{
  home.packages = with pkgs; [
    docker-buildx
    qemu
  ];
}
