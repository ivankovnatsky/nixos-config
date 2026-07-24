{ pkgs, ... }:
{
  home.packages = [
    pkgs.ranger
    pkgs.ffmpegthumbnailer
  ];
  home.file = {
    ".config/ranger/rc.conf" = {
      text = ''
        # ratio = parent, current, preview (matches yazi mgr.ratio)
        set column_ratios 1,2,4
        set show_hidden true
        set preview_images true
        set preview_images_method kitty
        set preview_script ${pkgs.ranger-scope}/scope.sh
      '';
    };
  };
}
