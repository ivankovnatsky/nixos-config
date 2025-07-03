{ config, pkgs, ... }:

{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-import
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.flags.homeWorkPath}/.password-store";
    };
  };
}
