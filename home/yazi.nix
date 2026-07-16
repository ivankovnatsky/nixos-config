{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "yy";

    plugins = {
      piper = pkgs.yaziPlugins.piper;
    };

    settings = {
      # ratio = [ parent, current, preview ]; middle = current dir listing.
      mgr.ratio = [
        1
        2
        4
      ];

      plugin.prepend_previewers =
        map
          (ext: {
            url = "*.${ext}";
            run = ''piper -- ${pkgs.yazi-gpg-preview} "$1"'';
          })
          [
            "gpg"
            "pgp"
            "asc"
          ];
    };
  };
}
