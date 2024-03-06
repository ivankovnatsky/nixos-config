{ pkgs, ... }:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin;
  homeDir = if isDarwin then "/Users" else "/home";
in
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp exts.pass-import ]);
    settings = {
      PASSWORD_STORE_DIR = "${homeDir}/ivan/.password-store/";
    };
  };
}
