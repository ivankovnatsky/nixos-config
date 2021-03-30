{ pkgs, ... }:

{
  programs = {
    gpg.enable = true;

    password-store = {
      enable = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    };

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
        "vo" = "gpu";
        "profile" = "gpu-hq";
        "gpu-context" = "wayland";
      };
    };

    taskwarrior = {
      enable = true;
      dataLocation = "/home/ivan/.task/";
    };
  };
}
