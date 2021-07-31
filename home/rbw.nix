{ pkgs, ... }:

let
  email = builtins.readFile ../.secrets/personal/email;
in
{
  programs.rbw = {
    enable = true;

    settings = {
      email = "${email}";
      lock_timeout = 2419200;
      pinentry = pkgs.pinentry;
    };
  };
}
