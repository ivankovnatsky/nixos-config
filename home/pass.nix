{ config, pkgs, ... }:

{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      # exts.pass-import — removed: pulls in python3-secretstorage → jeepney,
      # which currently breaks on darwin (jeepney 0.9 in nixpkgs is missing
      # `outcome` propagation and its installCheck calls dbus-run-session).
      # Re-add only if you need to migrate passwords from another manager.
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.flags.homeWorkPath}/.password-store";
    };
  };
}
