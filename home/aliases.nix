{
  config,
  lib,
  pkgs,
}:

let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;

  syncthingHomeDir =
    if isDarwin then "~/Library/Application\\ Support/Syncthing" else "~/.config/syncthing";

  commonShellAliases = {
    # TODO: add function nix-prefetch-url $url | xargs nix hash to-sri --type sha256
    g = "${pkgs.git}/bin/git";
    erd = "${pkgs.erdtree}/bin/erd --color auto --human -L 1 --layout inverted --icons --long --hidden";
    # Let's not use GNU Coreutils mkdir for now.
    mkdir = "mkdir -p";
    less = "less -RS";
    syncthing = "${pkgs.syncthing}/bin/syncthing serve --no-browser";
    stc = "${pkgs.stc-cli}/bin/stc -homedir ${syncthingHomeDir}";
  };

in
if config.flags.purpose == "home" then
  commonShellAliases
  // {
    rclone = "${pkgs.rclone}/bin/rclone -P";
    wl-copy = lib.mkIf isLinux "${pkgs.wl-clipboard}/bin/wl-copy -n";
  }
else
  commonShellAliases
  // {
    # We tenv version manager so pkgs interpolation is not needed.
    tf = "tofu";
    tg = "terragrunt";
    k = "${pkgs.kubectl}/bin/kubectl";
    argocd = "${pkgs.argocd}/bin/argocd --grpc-web";
  }
