{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.activation = {
    createAndSetPermissionsNetrc =
      let
        netrcContent = pkgs.writeText "tmp_netrc" ''
          default api.github.com login ivankovnatsky password ${config.secrets.gitApiTokenRepoScope}
        '';
      in
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        cp "${netrcContent}" "$HOME/.netrc"
        chmod 0600 "$HOME/.netrc"
      '';
  };
}
