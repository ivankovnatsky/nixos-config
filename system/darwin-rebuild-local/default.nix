# Local copy of darwin-rebuild with sudo timestamp fix
# Based on: https://github.com/nix-darwin/nix-darwin/blob/master/pkgs/nix-tools/darwin-rebuild.sh
{ pkgs, lib, ... }:

let
  extraPath = lib.makeBinPath (with pkgs; [ coreutils jq git ]);
  systemPath = lib.concatStringsSep ":" [
    "$HOME/.nix-profile/bin"
    "/etc/profiles/per-user/$USER/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
  path = "${extraPath}:${systemPath}";
  nixPath = lib.concatStringsSep ":" [
    "darwin-config=/etc/nix-darwin/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
in
{
  environment.systemPackages = [
    (pkgs.replaceVarsWith {
      name = "darwin-rebuild-local";
      src = ./darwin-rebuild.sh;
      dir = "bin";
      isExecutable = true;
      replacements = {
        inherit path nixPath;
        profile = "/nix/var/nix/profiles/system";
        shell = "${pkgs.stdenv.shell}";
      };
    })
  ];
}