{ pkgs, ... }:
{
  home.packages = [
    pkgs.ranger
    pkgs.ffmpegthumbnailer
  ];
  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        set show_hidden true
        set preview_images true
        set preview_images_method kitty
        set preview_script ${pkgs.ranger-scope}/scope.sh
      '';
    };
  };
}
