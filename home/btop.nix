{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    settings = {
      proc_sorting = "cpu lazy";
    };
  };
}
