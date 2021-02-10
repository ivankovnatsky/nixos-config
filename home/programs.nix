{ pkgs, ... }:

{
  programs = {

    bat = {
      enable = true;
      config = { tabs = "0"; };
    };

    mpv = {
      enable = true;
      config = {
        "alang" = "eng";
        "force-seekable" = "yes";
        "fs" = "yes";
        "hwdec" = "yes";
        "opengl-pbo" = "yes";
        "osc" = "no";
        "osd-level" = "0";
        "save-position-on-quit" = "yes";
        "slang" = "eng";
        "ytdl-format" = "bestvideo+bestaudio/best";
        "image-display-duration" = "5";
      };
    };

    ssh = {
      enable = true;

      extraConfig = ''
        Host *
          IdentityFile ~/.ssh/id_ed25519
          IdentityFile ~/.ssh/id_ed25519_work
      '';
    };

    taskwarrior = {
      enable = true;
      dataLocation = "/home/ivan/.task/";
    };
  };
}
